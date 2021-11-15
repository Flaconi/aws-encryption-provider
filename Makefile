REPO?=gcr.io/must-override
IMAGE?=aws-encryption-provider
TAG?=0.0.1

.PHONY: lint test build-docker build-server build-client login push

lint:
	echo "Verifying go mod tidy"
	hack/verify-mod-tidy.sh
	echo "Verifying vendored dependencies"
	hack/verify-vendor.sh
	echo "Verifying gofmt"
	hack/verify-gofmt.sh
	echo "Verifying linting"
	hack/verify-golint.sh

test:
	go test -mod vendor -v -cover -race ./...

build-docker:
	docker build \
		-t ${REPO}/${IMAGE}:latest \
		-t ${REPO}/${IMAGE}:${TAG} \
		--build-arg TAG=${TAG} .

build-server:
	go build -mod vendor -ldflags \
			"-w -s -X sigs.k8s.io/aws-encryption-provider/pkg/version.Version=${TAG}" \
			-o bin/aws-encryption-provider cmd/server/main.go

build-client:
	go build -mod vendor -ldflags "-w -s" -o bin/grpcclient cmd/client/main.go

login:
ifndef DOCKER_USER
	$(error DOCKER_USER must either be set via environment or parsed as argument)
endif
ifndef DOCKER_PASS
	$(error DOCKER_PASS must either be set via environment or parsed as argument)
endif
	@yes | docker login --username $(DOCKER_USER) --password $(DOCKER_PASS)

push:
	docker push ${REPO}/$(IMAGE):latest
	docker push ${REPO}/$(IMAGE):$(TAG)
