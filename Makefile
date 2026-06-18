qcow2:
	./build.sh

vmdk:
	IMAGE_TYPE=vmdk ./build.sh

build:
	podman build . --tag quay.io/rgolangh/fedora-image-mode-vm
