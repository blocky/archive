package main

import (
	"fmt"
	"os"
)

func main() {
	fmt.Printf("Hello from app 1 with args '%v'\n", os.Args[1:])
}
