# Fedora BootC VM Image Builder

Build bootable Fedora 43 virtual machine images using [bootc](https://containers.github.io/bootc/) (Image Mode for RHEL/Fedora) for VMware vSphere, VMware Workstation/Fusion, and KVM environments.

## What is BootC?

BootC (bootable container) is a new way to build and deploy operating systems using OCI container images. This project packages Fedora 43 with a Cinnamon desktop environment as a bootable VM image.

## Features

- **Fedora 43** base with Cinnamon desktop environment
- **VMware Tools** (open-vm-tools) pre-installed and configured
- **Cloud-init** for automated first-boot configuration
- **Firefox** browser included
- **XFS filesystem** (compatible with Migration Toolkit for Virtualization)
- **Multiple output formats**: QCOW2, VMDK, VMX, OVA

## Prerequisites

- Fedora/RHEL/CentOS Linux host
- Podman installed
- Sudo privileges
- At least 10GB free disk space

## Quick Start

### For vSphere/ESXi (OVA format)

```bash
make vmdk-ova
```

This creates a ready-to-deploy OVA file in `./output/Fedora-BootC-VM.ova`

Upload to vSphere and deploy as a new VM.

### For VMware Workstation/Fusion (VMX format)

```bash
make vmdk-vmx
```

This creates `./output/Fedora-BootC-VM.vmx` - open this file in VMware Workstation or Fusion.

### For KVM/libvirt (QCOW2 format)

```bash
make qcow2
```

This creates a QCOW2 disk image in `./output/qcow2/`

## Customization

### VM Configuration

Customize VM settings using environment variables:

```bash
VM_NAME=MyFedoraVM \
VM_DISPLAYNAME="My Custom Fedora Desktop" \
VM_MEMORY_MB=8192 \
VM_CPUS=4 \
VM_DISK_SIZE_GB=30 \
make vmdk-ova
```

Available variables:
- `VM_NAME` - VM identifier (default: `Fedora-BootC-VM`)
- `VM_DISPLAYNAME` - Display name in VMware (default: `Fedora BootC Desktop`)
- `VM_MEMORY_MB` - Memory in MB (default: `4096`)
- `VM_CPUS` - Number of vCPUs (default: `2`)
- `VM_DISK_SIZE_GB` - Disk size in GB (default: `20`)
- `VM_HARDWARE_VERSION` - VMware hardware version (default: `19`)
- `VM_GUEST_OS` - Guest OS type (default: `fedora-64`)

### SSH Access

Edit `config.toml` or `config-vmdk.toml` to add your SSH public key:

```toml
[[customizations.user]]
name = "cloud-user"
groups = ["wheel"]
key = "ssh-rsa YOUR_PUBLIC_KEY_HERE"
```

### Additional Packages

Edit `Containerfile` to add more packages:

```dockerfile
RUN dnf install -y \
    your-package-here \
    another-package
```

## Build Targets

Run `make help` to see all available targets:

- `make qcow2` - Build QCOW2 image for KVM/libvirt
- `make vmdk` - Build VMDK disk image only
- `make vmdk-vmx` - Build VMDK + VMX for VMware Workstation/Fusion
- `make vmdk-ova` - Build VMDK + OVA for vSphere/ESXi
- `make clean-vm` - Remove generated VM metadata files

## Deployment

### vSphere/ESXi

1. Build the OVA: `make vmdk-ova`
2. In vSphere client: **Deploy OVF Template**
3. Select `output/Fedora-BootC-VM.ova`
4. Follow the wizard to complete deployment
5. Power on the VM

### VMware Workstation/Fusion

1. Build the VMX: `make vmdk-vmx`
2. In VMware: **File → Open**
3. Select `output/Fedora-BootC-VM.vmx`
4. Power on the VM

### KVM/libvirt

1. Build the QCOW2: `make qcow2`
2. Use `virt-manager` or `virt-install` to create a VM with the generated QCOW2 disk

## First Boot

The VM uses cloud-init for initial configuration. On first boot:

1. Cloud-init configures the network
2. SSH key is installed for the `cloud-user` account
3. VMware tools start automatically

Login credentials:
- Username: `cloud-user` (configured in config.toml)
- Authentication: SSH key only (no password by default)

To set a password after first boot:
```bash
ssh cloud-user@<vm-ip>
sudo passwd cloud-user
```

## Architecture

```
┌─────────────────┐
│  Containerfile  │  Base image + packages + services
└────────┬────────┘
         │ podman build
         ▼
┌─────────────────┐
│ Bootc Container │  OCI container image
└────────┬────────┘
         │ bootc-image-builder
         ▼
┌─────────────────┐
│   VMDK Disk     │  Virtual disk image
└────────┬────────┘
         │ create-ovf.sh (optional)
         ▼
┌─────────────────┐
│   OVA/VMX       │  Deployable VM package
└─────────────────┘
```

## Files

- `Containerfile` - Container image definition
- `build.sh` - Main build script
- `config.toml` - QCOW2 configuration (includes filesystem settings)
- `config-vmdk.toml` - VMDK/OVA configuration (user settings only)
- `create-ovf.sh` - OVF descriptor generator
- `Makefile` - Build automation and VM metadata generation

## Troubleshooting

### Build fails with "filesystem customization not supported"

This happens when using `config.toml` (which has filesystem settings) for VMDK builds. The build script automatically uses `config-vmdk.toml` for VMDK/OVA builds to avoid this.

### VMDK won't import to vSphere

Use the OVA format instead: `make vmdk-ova`

Raw VMDK files are difficult to import. The OVA includes all necessary metadata.

### Permission denied during build

The build requires sudo for podman. You'll be prompted for your password during the build.

## License

This is a build configuration repository. Component licenses:
- Fedora: Various open source licenses
- bootc: Apache 2.0
- open-vm-tools: GPL/LGPL

## Contributing

Contributions welcome! Please ensure your changes:
1. Work with both QCOW2 and VMDK outputs
2. Don't break existing build targets
3. Include documentation updates

## References

- [BootC Project](https://containers.github.io/bootc/)
- [bootc-image-builder](https://github.com/osbuild/bootc-image-builder)
- [Fedora Bootc](https://quay.io/repository/fedora/fedora-bootc)
- [Cloud-init Documentation](https://cloudinit.readthedocs.io/)
