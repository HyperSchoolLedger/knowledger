package main

import (
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/gorilla/mux"
)

func greet(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Hello World! %s", time.Now())
}

func main() {

	router := mux.NewRouter()
	router.HandleFunc("/greet", greet).Methods("GET")
	if err := http.ListenAndServe(":3000", router); err != nil {
		log.Fatal(err)
	}
}
