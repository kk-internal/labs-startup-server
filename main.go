package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/google/uuid"
)

type Logger struct {
	requestID string
}

func (l *Logger) Info(msg string, data map[string]string) {
	entry := map[string]interface{}{
		"level":      "info",
		"timestamp":  time.Now().UTC().Format(time.RFC3339),
		"request_id": l.requestID,
		"message":    msg,
		"data":       data,
	}
	jsonData, _ := json.Marshal(entry)
	fmt.Println(string(jsonData))
}

func (l *Logger) Error(msg string, err error) {
	entry := map[string]interface{}{
		"level":      "error",
		"timestamp":  time.Now().UTC().Format(time.RFC3339),
		"request_id": l.requestID,
		"message":    msg,
		"error":      err.Error(),
	}
	jsonData, _ := json.Marshal(entry)
	fmt.Println(string(jsonData))
}

type contextKey string

const requestIDKey contextKey = "requestID"

func requestIDMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		requestID := uuid.New().String()
		ctx := context.WithValue(r.Context(), requestIDKey, requestID)
		w.Header().Set("X-Request-ID", requestID)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

func startupHandler(server *http.Server) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		requestID := r.Context().Value(requestIDKey).(string)
		logger := &Logger{requestID: requestID}

		queryParams := r.URL.Query()
		envVars := make(map[string]string)

		for key, values := range queryParams {
			if len(values) > 0 {
				envVars[key] = values[0]
			}
		}

		logger.Info("Startup setting env to", envVars)

		file, err := os.Create(".env")
		if err != nil {
			logger.Error("Failed to create .env file", err)
			http.Error(w, "error", http.StatusInternalServerError)
			return
		}

		for key, value := range envVars {
			_, err := file.WriteString(fmt.Sprintf("%s=%s\n", key, value))
			if err != nil {
				logger.Error("Failed to write to .env file", err)
				file.Close()
				http.Error(w, "error", http.StatusInternalServerError)
				return
			}
		}
		file.Close()

		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))

		// Shutdown server in background
		go func() {
			time.Sleep(100 * time.Millisecond)
			logger.Info("Killing startup server", nil)
			if err := server.Shutdown(context.Background()); err != nil {
				log.Printf("Server shutdown error: %v", err)
			}
			os.Exit(0)
		}()
	}
}

func heartBeatHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("success"))
}

func main() {
	mux := http.NewServeMux()

	server := &http.Server{
		Addr:    ":8081",
		Handler: requestIDMiddleware(mux),
	}

	mux.HandleFunc("/", startupHandler(server))
	mux.HandleFunc("/heart_beat", heartBeatHandler)

	log.Printf("Starting server on :8081")
	if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		log.Fatalf("Server error: %v", err)
	}
}
