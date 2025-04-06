IMAGE_NAME=gobase
TAG=latest

DEV_IMAGE_NAME=go-dev-env
DEV_TAG=latest
DEV_CONTAINER_NAME=go-dev-container

colon := :
GO_IMAGE=docker.io/library/golang$(colon)1.24-alpine
MODULE_NAME=goapp

# --- PROD ---
run: build ## Build the image and run the container
	podman run -it --rm $(IMAGE_NAME):$(TAG)

build: ## Build to container image
	podman build --rm -t $(IMAGE_NAME):$(TAG) .

clean: ## Remove dangling images
	@echo "Pruning dangling images..."
	@podman image prune -f || true

# --- DEV ---
dev-build: ## Build the development environment image (if needed)
	podman build -f Dockerfile.dev -t $(DEV_IMAGE_NAME):$(DEV_TAG) .

dev: dev-build ## Start the persistent development container in the background
	@echo "--- Checking if development container '$(DEV_CONTAINER_NAME)' is running..."
	@if podman ps -q --filter name=^/${DEV_CONTAINER_NAME}$$ | grep -q .; then \
		echo "--- Container '$(DEV_CONTAINER_NAME)' is already running."; \
		else \
		echo "--- Starting container '$(DEV_CONTAINER_NAME)'..."; \
		podman rm $(DEV_CONTAINER_NAME) >/dev/null 2>&1 || true; \
		podman run -d \
			--name $(DEV_CONTAINER_NAME) \
			-v ./goapp:/app \
			-w /app \
			$(DEV_IMAGE_NAME):$(DEV_TAG) \
			tail -f /dev/null; \
		echo "--- Container started. Mounts ./goapp to /app inside."; \
		echo "--- Run 'make dev-exec' to run your app inside."; \
		echo "--- Run 'make dev-stop' to stop and remove it."; \
	fi

dev-stop: ## Stop and remove the persistent development container
	@echo "--- Stopping and removing container '$(DEV_CONTAINER_NAME)'..."
	@podman stop $(DEV_CONTAINER_NAME) >/dev/null 2>&1 || true
	@podman rm $(DEV_CONTAINER_NAME) >/dev/null 2>&1 || true
	@echo "--- Container stopped and removed (if it existed)."

# Target to execute the go run command inside the running dev container
dev-run: ## Run the Go application inside the running development container
	@echo "--- Executing 'go run server.go' inside container '$(DEV_CONTAINER_NAME)'..."
	@if ! podman ps -q --filter name=^/${DEV_CONTAINER_NAME}$$ | grep -q .; then \
		echo "--- Error: Container '$(DEV_CONTAINER_NAME)' is not running. Run 'make dev' first."; \
		exit 1; \
	fi
	podman exec -it -w /app $(DEV_CONTAINER_NAME) go run server.go # Use go run for quick iteration

# Target to open a shell inside the running dev container
dev-shell: ## Open an interactive shell inside the running development container
	@echo "--- Opening shell inside container '$(DEV_CONTAINER_NAME)'..."
	@if ! podman ps -q --filter name=^/${DEV_CONTAINER_NAME}$$ | grep -q .; then \
		echo "--- Error: Container '$(DEV_CONTAINER_NAME)' is not running. Run 'make dev' first."; \
		exit 1; \
	fi
	podman exec -it -w /app $(DEV_CONTAINER_NAME) sh # Or bash if available

# --- GO MOD ---
go_mod_init: ## Initialize go.mod inside the goapp directory using a container
	@echo "--- Ensuring goapp directory exists..."
	@mkdir -p goapp
	@echo "--- Running go mod init $(MODULE_NAME) in $(GO_IMAGE)..."
	@podman run --rm -it \
		-v ./goapp:/app \
		-w /app \
		$(GO_IMAGE) \
		go mod init $(MODULE_NAME)
	@echo "--- go.mod should now exist in ./goapp/"
	@ls -l ./goapp/go.mod # Show the result

go_mod_tidy: ## Tidy go modules (add dependencies to go.sum) inside goapp using a container
	@echo "--- Running go mod tidy in $(GO_IMAGE)..."
	@podman run --rm -it \
		-v ./goapp:/app \
		-w /app \
		$(GO_IMAGE) \
		go mod tidy
	@echo "--- go.mod and go.sum should now be updated in ./goapp/"
	@ls -l ./goapp/go.mod ./goapp/go.sum # Show the result

.PHONY: run, build, clean, go_mod_init, go_mod_tidy, dev-build dev dev-stop dev-exec dev-shell

