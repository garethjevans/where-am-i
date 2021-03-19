SHELL := /bin/bash
NAME := where-am-i
BINARY_NAME := where-am-i
GO := GO111MODULE=on GO15VENDOREXPERIMENT=1 go
GO_NOMOD := GO111MODULE=off go
PACKAGE_NAME := github.com/garethjevans/where-am-i
ROOT_PACKAGE := github.com/garethjevans/where-am-i
ORG := garethjevans

# set dev version unless VERSION is explicitly set via environment
VERSION ?= $(shell echo "$$(git describe --abbrev=0 --tags 2>/dev/null)-dev+$(REV)" | sed 's/^v//')

GO_VERSION       := $(shell $(GO) version | sed -e 's/^[^0-9.]*\([0-9.]*\).*/\1/')
PACKAGE_DIRS     := $(shell $(GO) list ./... | grep -v /vendor/ | grep -v e2e)
PEGOMOCK_PACKAGE := github.com/petergtz/pegomock
GO_DEPENDENCIES  := $(shell find . -type f -name '*.go')

REV              := $(shell git rev-parse --short HEAD 2> /dev/null || echo 'unknown')
SHA1             := $(shell git rev-parse HEAD 2> /dev/null || echo 'unknown')
BRANCH           := $(shell git rev-parse --abbrev-ref HEAD 2> /dev/null || echo 'unknown')
BUILD_DATE       := $(shell date +%Y%m%d-%H:%M:%S)
INSPECT_LABELS   := $(shell inspect labels 2> /dev/null || echo '--label "inspect.not.installed=true"')

BUILDFLAGS := -trimpath -ldflags \
  " -X $(ROOT_PACKAGE)/pkg/version.Version=$(VERSION)\
		-X $(ROOT_PACKAGE)/pkg/version.Revision=$(REV)\
		-X $(ROOT_PACKAGE)/pkg/version.BuiltBy=make \
		-X $(ROOT_PACKAGE)/pkg/version.Sha1=$(SHA1)\
		-X $(ROOT_PACKAGE)/pkg/version.Branch='$(BRANCH)'\
		-X $(ROOT_PACKAGE)/pkg/version.BuildDate='$(BUILD_DATE)'\
		-X $(ROOT_PACKAGE)/pkg/version.GoVersion='$(GO_VERSION)'"
CGO_ENABLED = 0
BUILDTAGS :=

GOPATH1=$(firstword $(subst :, ,$(GOPATH)))

export PATH := $(PATH):$(GOPATH1)/bin

build: $(GO_DEPENDENCIES)
	CGO_ENABLED=$(CGO_ENABLED) $(GO) build $(BUILDTAGS) $(BUILDFLAGS) -o build/$(BINARY_NAME) main.go

linux: $(GO_DEPENDENCIES)
	CGO_ENABLED=$(CGO_ENABLED) GOOS=linux GOARCH=amd64 $(GO) build $(BUILDFLAGS) -o build/linux/$(NAME) main.go
	chmod +x build/linux/$(NAME)

dist: $(GO_DEPENDENCIES)
	CGO_ENABLED=$(CGO_ENABLED) GOOS=linux GOARCH=amd64 $(GO) build $(BUILDFLAGS) -o dist/where-am-i-linux_linux_amd64/$(NAME) main.go
	chmod +x dist/where-am-i-linux_linux_amd64/$(NAME)
	docker build --platform linux/amd64 -t garethjevans/where-am-i:dev $(INSPECT_LABELS) .
	docker push garethjevans/where-am-i:dev --disable-content-trust=true

diff:
	helm diff upgrade --install where-am-i charts/where-am-i --set image.pullPolicy=Always --set replicaCount=1 

deploy:
	helm upgrade --install where-am-i charts/where-am-i --set image.pullPolicy=Always --set replicaCount=1

arm: $(GO_DEPENDENCIES)
	CGO_ENABLED=$(CGO_ENABLED) GOOS=linux GOARCH=arm $(GO) build $(BUILDFLAGS) -o build/arm/$(NAME) main.go
	chmod +x build/arm/$(NAME)

win: $(GO_DEPENDENCIES)
	CGO_ENABLED=$(CGO_ENABLED) GOOS=windows GOARCH=amd64 $(GO) build $(BUILDFLAGS) -o build/win/$(NAME)-windows-amd64.exe main.go

darwin: $(GO_DEPENDENCIES)
	CGO_ENABLED=$(CGO_ENABLED) GOOS=darwin GOARCH=amd64 $(GO) build $(BUILDFLAGS) -o build/darwin/$(NAME) main.go
	chmod +x build/darwin/$(NAME)

all: version check

check: fmt lint build test

version:
	echo "Go version: $(GO_VERSION)"

test:
	DISABLE_SSO=true CGO_ENABLED=$(CGO_ENABLED) $(GO) test -coverprofile=coverage.out $(PACKAGE_DIRS)

testv:
	DISABLE_SSO=true CGO_ENABLED=$(CGO_ENABLED) $(GO) test -test.v $(PACKAGE_DIRS)

testrich:
	DISABLE_SSO=true CGO_ENABLED=$(CGO_ENABLED) richgo test -test.v $(PACKAGE_DIRS)

test1:
	DISABLE_SSO=true CGO_ENABLED=$(CGO_ENABLED) $(GO) test  -count=1  -short ./... -test.v  -run $(TEST)

cover:
	$(GO) tool cover -func coverage.out | grep total

coverage:
	$(GO) tool cover -html=coverage.out

install: $(GO_DEPENDENCIES)
	GOBIN=${GOPATH1}/bin $(GO) install $(BUILDFLAGS) cmd/$(NAME)/$(NAME).go

get-fmt-deps: ## Install goimports
	$(GO_NOMOD) get golang.org/x/tools/cmd/goimports

importfmt: get-fmt-deps
	@echo "Formatting the imports..."
	goimports -w $(GO_DEPENDENCIES)

fmt: importfmt
	@FORMATTED=`$(GO) fmt $(PACKAGE_DIRS)`
	@([[ ! -z "$(FORMATTED)" ]] && printf "Fixed unformatted files:\n$(FORMATTED)") || true

clean:
	rm -rf build release

modtidy:
	$(GO) mod tidy

mod: modtidy build

.PHONY: dist release clean


generate-fakes:
	$(GO) generate ./...

generate-all: generate-fakes

.PHONY: goreleaser
goreleaser:
	step-go-releaser --organisation=$(ORG) --revision=$(REV) --branch=$(BRANCH) --build-date=$(BUILD_DATE) --go-version=$(GO_VERSION) --root-package=$(ROOT_PACKAGE) --version=$(VERSION)

lint:
	golangci-lint run
