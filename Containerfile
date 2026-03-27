FROM quay.io/fedora/fedora-bootc:42

# VMware tools for vSphere integration
RUN dnf install -y \
    open-vm-tools \
    cloud-init \
    cloud-utils-growpart \
    && dnf clean all

# Enable VMware tools and cloud-init for first-boot config
RUN systemctl enable vmtoolsd.service \
    && systemctl enable cloud-init.service \
    && systemctl enable cloud-init-local.service \
    && systemctl enable cloud-config.service \
    && systemctl enable cloud-final.service

# Configure cloud-init datasource for vSphere (VMware GuestInfo)
COPY etc/cloud/cloud.cfg.d/99_vsphere.cfg /etc/cloud/cloud.cfg.d/99_vsphere.cfg
COPY etc/cloud/cloud.cfg.d/50_growpart.cfg /etc/cloud/cloud.cfg.d/50_growpart.cfg
COPY usr/local/bin/fill-root-50pct.sh /usr/local/bin/fill-root-50pct.sh
RUN chmod +x /usr/local/bin/fill-root-50pct.sh
