DISTRO=kinetic

IMAGE=jaci/ros:$(DISTRO)
IMAGE_TYPES=ros-base robot perception desktop desktop-full

ALL_BUILDS=$(patsubst %, build-%, $(IMAGE_TYPES))
ALL_PUSHES=push-ros-core $(patsubst %, push-%, 	$(IMAGE_TYPES))

.PHONY: all build push build-ros-core $(ALL_BUILDS) $(ALL_PUSHES)

all: build push

build-ros-base: build-ros-core
build-robot: build-ros-base
build-perception: build-ros-base
build-desktop: build-robot
build-desktop-full: build-desktop

build-ros-core:
	@echo BUILD :: ros-core
	docker build -t $(IMAGE)-ros-core .

$(ALL_BUILDS): build-%:
	@echo BUILD :: $*
	docker build -t $(IMAGE)-$* --build-arg baseimg=$(IMAGE)-$(^:build-%=%) --build-arg package=$* -f Dockerfile.child .

build: build-ros-core $(ALL_BUILDS)

push-ros-base: push-ros-core
push-robot: push-ros-base
push-perception: push-ros-base
push-desktop: push-robot
push-desktop-full: push-desktop

$(ALL_PUSHES): push-%: build-%
	@echo PUSH :: $*
	docker push $(IMAGE)-$*

push: push-ros-core $(ALL_PUSHES)
	docker tag $(IMAGE)-desktop-full $(IMAGE)
	docker push $(IMAGE)