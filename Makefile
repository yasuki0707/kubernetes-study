.PHONY: build view

MKDOCS     ?= squidfunk/mkdocs-material
DOCKER_RUN =  docker run --rm -it
MOUNT      =  -v ${PWD}:/docs
PORT       =  -p 8000:8000

init:
	rm ./.git -rf

build:
	$(DOCKER_RUN) $(MOUNT) $(MKDOCS) build --clean

view:
	$(DOCKER_RUN) $(PORT) $(MOUNT) $(MKDOCS)