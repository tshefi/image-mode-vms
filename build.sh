#!/bin/bash
set -euo pipefail

IMAGE_TYPE="${IMAGE_TYPE:-qcow2}"
IMAGE_NAME="${IMAGE_NAME:-localhost/fedora-vsphere-vm}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
OUTPUT_DIR="${OUTPUT_DIR:-./output}"

# Use different config for vmdk (filesystem customization not supported)
if [[ $IMAGE_TYPE = "vmdk" ]]; then
    CONFIG_FILE="${PWD}/config-vmdk.toml"
else
    CONFIG_FILE="${PWD}/config.toml"
fi

echo "==> Building bootc container image: ${IMAGE_NAME}:${IMAGE_TAG}"
sudo podman build --network host -t "${IMAGE_NAME}:${IMAGE_TAG}" .

echo "==> Converting to $IMAGE_TYPE using bootc-image-builder"
mkdir -p "${OUTPUT_DIR}"

sudo podman run \
    --rm \
    -it \
    --privileged \
    --pull=newer \
    --security-opt label=type:unconfined_t \
    -v "${OUTPUT_DIR}":/output \
    -v "${CONFIG_FILE}":/config.toml \
    -v "/var/lib/containers/storage":/var/lib/containers/storage \
    quay.io/centos-bootc/bootc-image-builder:latest \
    --verbose \
    --type $IMAGE_TYPE \
    --rootfs xfs \
    --config /config.toml \
    "${IMAGE_NAME}:${IMAGE_TAG}"

echo "==> Fixing ownership of output files..."
sudo chown -R "${USER}:${USER}" "${OUTPUT_DIR}"

echo "==> Done! $IMAGE_TYPE is in ${OUTPUT_DIR}/"
if [[ $IMAGE_TYPE = "vmdk" ]]; then
    echo "    Upload the .${IMAGE_TYPE} file to your vSphere datastore and create a VM from it."
fi
