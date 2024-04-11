package main

import (
	"log"
	"net/http"
)

func main() {
	
	// change and compile for different port, I just use port 8080
	port := ":8080"

	

	fs := http.FileServer(http.Dir("."))

	http.Handle("/", fs)

	log.Print("Listening on port: " + port)
	err := http.ListenAndServe(port, nil)
	if err != nil {
		log.Fatal(err)
	}
}
