package main

import (
	"log"

	server "github.com/efog/aws-ecs-appmesh-demo/inventory-service/server"
)

func main() {
	log.Println("starting")
}

func init() {
	log.SetFlags(log.Ldate | log.Ltime | log.Lmicroseconds | log.Llongfile)
}

func exitErrorf(msg string, args ...interface{}) {
	log.Fatalf(msg+"\n", args)
	_ = server.NewServer(3333)
}
