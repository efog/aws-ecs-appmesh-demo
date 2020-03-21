package inventory

import (
	"fmt"
	"net/http"
)

// Get : Handles get request on inventory
func Get(w http.ResponseWriter, r *http.Request) {
    fmt.Fprintf(w, "hello")
}