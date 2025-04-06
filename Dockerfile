FROM docker.io/library/golang:1.24-alpine AS builder
WORKDIR /app
COPY ./goapp/go.mod ./goapp/go.sum ./
RUN go mod download
COPY ./goapp .
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -v -o /server server.go


FROM alpine
WORKDIR /opt
COPY --from=builder /server /opt/server
ENTRYPOINT ["/opt/server"]

