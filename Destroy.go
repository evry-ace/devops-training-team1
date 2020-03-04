package main

import (
	"bytes"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"time"
)

func main() {

	// Decleare variables for input arguments
	token := "1234abc"
	text := "test"

	// Handle input arguments
	if len(os.Args) == 2 {
		token = os.Args[1]
		text = "test"
	} else if len(os.Args) == 3 {
		token = os.Args[1]
		text = os.Args[2]
	} else {
		fmt.Println("Wrong number of arguments")
		os.Exit(2)
	}

	// dispatcher Url
	url := "https://api.github.com/repos/evry-ace/devops-training-team1/dispatches"

	// request data
	data := []byte(`{"event_type": "do-something", "client_payload": { "text": "` + text + `"}}`)

	// Create the request
	req, err := http.NewRequest("POST", url, bytes.NewBuffer(data))
	if err != nil {
		log.Fatal("Error reading request. ", err)
	}

	// Set headers
	req.Header.Set("Accept", "application/vnd.github.everest-preview+json")
	req.Header.Set("Authorization", "token "+token+"")

	// Set client timeout
	client := &http.Client{Timeout: time.Second * 10}

	// Send request
	resp, err := client.Do(req)
	if err != nil {
		log.Fatal("Error reading response. ", err)
	}
	defer resp.Body.Close()

	// Display the response
	fmt.Println("response Status:", resp.Status)
	fmt.Println("response Headers:", resp.Header)

	// Display response errors
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		log.Fatal("Error reading body. ", err)
	}

	// Display the body data
	fmt.Printf("%s\n", body)
}
