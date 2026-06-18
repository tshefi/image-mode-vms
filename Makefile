# VM Metadata Variables (can be overridden)
VM_NAME ?= Fedora-BootC-VM
VM_DISPLAYNAME ?= Fedora BootC Desktop
VM_MEMORY_MB ?= 4096
VM_CPUS ?= 2
VM_DISK_SIZE_GB ?= 20
VM_HARDWARE_VERSION ?= 19
VM_GUEST_OS ?= fedora-64
OUTPUT_DIR ?= ./output

# Derived filenames
VMDK_DISK = vmdk/disk.vmdk
VMX_FILE = $(OUTPUT_DIR)/$(VM_NAME).vmx
OVF_FILE = $(OUTPUT_DIR)/$(VM_NAME).ovf
OVA_FILE = $(OUTPUT_DIR)/$(VM_NAME).ova

.PHONY: qcow2 vmdk vmdk-ova clean-vm help

qcow2:
	./build.sh

# Build VMDK disk image only
vmdk:
	IMAGE_TYPE=vmdk ./build.sh

# Build VMDK + create VMX file for VMware Workstation/Fusion
vmdk-vmx: vmdk
	@echo "==> Generating VMX configuration file..."
	@printf '.encoding = "UTF-8"\n' > $(VMX_FILE)
	@printf 'config.version = "8"\n' >> $(VMX_FILE)
	@printf 'virtualHW.version = "%s"\n' "$(VM_HARDWARE_VERSION)" >> $(VMX_FILE)
	@printf 'vmci0.present = "TRUE"\n' >> $(VMX_FILE)
	@printf 'displayName = "%s"\n' "$(VM_DISPLAYNAME)" >> $(VMX_FILE)
	@printf 'guestOS = "%s"\n' "$(VM_GUEST_OS)" >> $(VMX_FILE)
	@printf 'memsize = "%s"\n' "$(VM_MEMORY_MB)" >> $(VMX_FILE)
	@printf 'numvcpus = "%s"\n' "$(VM_CPUS)" >> $(VMX_FILE)
	@printf 'scsi0.present = "TRUE"\n' >> $(VMX_FILE)
	@printf 'scsi0.virtualDev = "lsilogic"\n' >> $(VMX_FILE)
	@printf 'scsi0:0.present = "TRUE"\n' >> $(VMX_FILE)
	@printf 'scsi0:0.fileName = "%s"\n' "$(VMDK_DISK)" >> $(VMX_FILE)
	@printf 'scsi0:0.deviceType = "scsi-hardDisk"\n' >> $(VMX_FILE)
	@printf 'ethernet0.present = "TRUE"\n' >> $(VMX_FILE)
	@printf 'ethernet0.connectionType = "nat"\n' >> $(VMX_FILE)
	@printf 'ethernet0.virtualDev = "vmxnet3"\n' >> $(VMX_FILE)
	@printf 'ethernet0.addressType = "generated"\n' >> $(VMX_FILE)
	@printf 'usb.present = "TRUE"\n' >> $(VMX_FILE)
	@printf 'sound.present = "TRUE"\n' >> $(VMX_FILE)
	@printf 'sound.virtualDev = "hdaudio"\n' >> $(VMX_FILE)
	@echo "==> VMX file created: $(VMX_FILE)"
	@echo "    Import this file into VMware Workstation/Fusion"

# Build VMDK + create OVF + package as OVA for vSphere
vmdk-ova: vmdk
	@echo "==> Creating OVF descriptor..."
	@./create-ovf.sh "$(OUTPUT_DIR)" "$(VM_NAME)" "$(VM_DISPLAYNAME)" "$(VM_MEMORY_MB)" "$(VM_CPUS)" "$(VM_DISK_SIZE_GB)" "$(VMDK_DISK)"
	@echo "==> Copying VMDK to output root for OVA packaging..."
	@cp "$(OUTPUT_DIR)/$(VMDK_DISK)" "$(OUTPUT_DIR)/disk.vmdk"
	@echo "==> Packaging OVA..."
	@cd $(OUTPUT_DIR) && tar -cvf $(VM_NAME).ova $(VM_NAME).ovf disk.vmdk
	@echo "==> OVA created: $(OVA_FILE)"
	@echo "    Upload and deploy this to vSphere/ESXi"

build:
	podman build . --tag quay.io/tshefi/fedora-image-mode-vm

clean-vm:
	rm -f $(VMX_FILE) $(OVF_FILE) $(OVA_FILE) $(OUTPUT_DIR)/disk.vmdk

help:
	@echo "Available targets:"
	@echo "  make qcow2          - Build QCOW2 image for KVM/libvirt"
	@echo "  make vmdk           - Build VMDK disk image only"
	@echo "  make vmdk-vmx       - Build VMDK + VMX for VMware Workstation/Fusion"
	@echo "  make vmdk-ova       - Build VMDK + OVA for vSphere/ESXi"
	@echo "  make clean-vm       - Remove generated VM metadata files"
	@echo ""
	@echo "Customization variables:"
	@echo "  VM_NAME=$(VM_NAME)"
	@echo "  VM_DISPLAYNAME=$(VM_DISPLAYNAME)"
	@echo "  VM_MEMORY_MB=$(VM_MEMORY_MB)"
	@echo "  VM_CPUS=$(VM_CPUS)"
	@echo "  VM_DISK_SIZE_GB=$(VM_DISK_SIZE_GB)"
	@echo ""
	@echo "Example: make vmdk-ova VM_NAME=MyVM VM_MEMORY_MB=8192 VM_CPUS=4"
