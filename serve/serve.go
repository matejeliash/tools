package main

import (
	"log"
	"net/http"
	"net"
	"os"
)

// GetLocalIP returns the non loopback local IP of the host
func GetLocalIP() string {
    addrs, err := net.InterfaceAddrs()
    if err != nil {
        return ""
    }
    for _, address := range addrs {
        // check the address type and if it is not a loopback the display it
        if ipnet, ok := address.(*net.IPNet); ok && !ipnet.IP.IsLoopback() {
            if ipnet.IP.To4() != nil {
                return ipnet.IP.String()
            }
        }
    }
    return ""
}

func main() {
	
	// change and compile for different port, I just use port 8080
	port := ":3000"

	ipAdress := GetLocalIP()
		
	pwd, _ := os.Getwd()
	fs := http.FileServer(http.Dir(pwd))
	
	log.Println(pwd)
	http.Handle("/", fs)

	log.Printf("Listening on %s%s ", ipAdress, port)
	err := http.ListenAndServe(port, nil)
	if err != nil {
		log.Fatal(err)
	}
}
