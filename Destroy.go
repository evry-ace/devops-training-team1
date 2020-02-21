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

	//boolPtr := flag.Bool("Destroy", false, "Do you realy whant to destroy infrastruktire (default=false)")
	//flag.Parse()

	token := "1234abc"
	text := "test"

	if len(os.Args) == 2 {
		token = os.Args[1]
		text = "test"
	} else if len(os.Args) == 3 {
		token = os.Args[1]
		text = os.Args[2]
	} else {
		fmt.Println("Wrong number of parameters")
		os.Exit(2)
	}

	url := "https://api.github.com/repos/evry-ace/devops-training-team1/dispatches"

	//data := []byte(`{"event_type": "do-something", "client_payload": { "text": "a title"}}`)
	data := []byte(`{"event_type": "do-something", "client_payload": { "text": "` + text + `"}}`)

	req, err := http.NewRequest("POST", url, bytes.NewBuffer(data))
	if err != nil {
		log.Fatal("Error reading request. ", err)
	}

	// Set headers
	req.Header.Set("Accept", "application/vnd.github.everest-preview+json")
	req.Header.Set("Authorization", "token "+token+"")

	// Create and Add cookie to request
	// cookie := http.Cookie{Name: "cookie_name", Value: "cookie_value"}
	// req.AddCookie(&cookie)

	// Set client timeout
	client := &http.Client{Timeout: time.Second * 10}

	// Validate cookie and headers are attached
	// fmt.Println(req.Cookies())
	// fmt.Println(req.Header)

	// Send request
	resp, err := client.Do(req)
	if err != nil {
		log.Fatal("Error reading response. ", err)
	}
	defer resp.Body.Close()

	fmt.Println("response Status:", resp.Status)
	fmt.Println("response Headers:", resp.Header)

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		log.Fatal("Error reading body. ", err)
	}

	fmt.Printf("%s\n", body)
}
