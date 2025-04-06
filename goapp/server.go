package main

import (
	// Standard library import (keep or remove if not used)
	// "fmt"

	// Import the third-party library
	// We are aliasing it to 'log' for convenience
	log "github.com/sirupsen/logrus"
)

func main() {
	// Replace the standard fmt.Println with a logrus call
	log.SetFormatter(&log.TextFormatter{
		FullTimestamp: true, // Optional: make logs look nicer
	})
	log.SetLevel(log.InfoLevel) // Set the minimum log level to show

	log.Info("Hello, World! Now using Logrus for logging!")
	log.Info("Dev container running!")

	// You can add other log levels too
	log.Warn("This is a warning message.")
	// log.Debug("This debug message won't show unless SetLevel is log.DebugLevel")
}
