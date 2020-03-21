package server

import (
	inventory "github.com/efog/aws-ecs-appmesh-demo/inventory-service/server/routes/inventory"
	"github.com/gorilla/mux"
)

// Server : simple http server
type Server struct {
	Router *mux.Router
}

// NewServer : instantiates new server
func NewServer(port int) *Server {
	router := mux.NewRouter().StrictSlash(true)
	router.HandleFunc("/", inventory.Get).Methods("GET")
	return &Server{
		Router: router,
	}
}
