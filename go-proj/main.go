package main

import (
	"fmt"
	"runtime"

	"rsc.io/sampler"
)

func main() {
	fmt.Println(sampler.Hello())
	fmt.Println(runtime.GOOS)
	fmt.Println(runtime.GOARCH)
}
