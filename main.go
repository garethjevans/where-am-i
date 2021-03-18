package main

import (
	"fmt"
	"os"
)

func main() {
	fmt.Printf("is running in docker %t\n", isRunningInDockerContainer())
	fmt.Printf("is running in kubernetes %t\n", isRunningInKubernetes())
}

func isRunningInDockerContainer() bool {
	// docker creates a .dockerenv file at the root
	// of the directory tree inside the container.
	// if this file exists then the viewer is running
	// from inside a container so return true

	if _, err := os.Stat("/.dockerenv"); err == nil {
		return true
	}

	return false
}

func isRunningInKubernetes() bool {
	// if the dir /var/run/secrets/kubernetes.io exists assume we are running in k8s
	if _, err := os.Stat("/var/run/secrets/kubernetes.io"); err == nil {
		return true
	}

	// otherwise, lets check the existance of the kubernetes service host variable
	if os.Getenv("KUBERNETES_SERVICE_HOST") != "" {
		return true
	}

	return false
}
