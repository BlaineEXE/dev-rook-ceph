# This Dockerfile sets up a Ceph build environment

# FROM opensuse/leap:15.2
FROM opensuse/tumbleweed

RUN zypper --gpg-auto-import-keys --non-interactive install --no-recommends \
        ccache git

# Requirements copied straight from install-deps.sh
RUN zypper --gpg-auto-import-keys --non-interactive install --no-recommends \
        babeltrace-devel \
        bc \
        btrfsprogs \
        cmake \
        cryptsetup \
        cunit-devel \
        fdupes \
        fuse-devel \
        gcc-c++ \
        gdbm \
        golang-github-prometheus-prometheus \
        gperf \
        gperftools-devel '>=' 2.4 \
        jq \
        keyutils-devel \
        leveldb-devel '>' 1.2 \
        libaio-devel \
        libblkid-devel '>=' 2.17 \
        libbz2-devel \
        libcap-ng-devel \
        libcurl-devel \
        libexpat-devel \
        liblz4-devel '>=' 1.7 \
        libnl3-devel \
        liboath-devel \
        libopenssl-devel \
        libtool \
        libudev-devel \
        libuuid-devel \
        libxml2-devel \
        libxmlsec1-1 \
        libxmlsec1-nss1 \
        libxmlsec1-openssl1 \
        lsb-release \
        lttng-ust-devel \
        make \
        mozilla-nss-devel \
        net-tools \
        openldap2-devel \
        parted \
        perl \
        pkgconfig \
        'pkgconfig(systemd)' \
        procps \
        python3 \
        python3-base \
        python3-bcrypt \
        python3-CherryPy \
        python3-coverage \
        python3-Cython \
        python3-devel \
        python3-nose \
        python3-numpy-devel \
        python3-pecan \
        python3-python-dateutil \
        python3-PrettyTable \
        python3-PyJWT \
        python3-requests \
        python3-Routes \
        python3-setuptools \
        python3-Sphinx \
        python3-tox \
        python3-virtualenv \
        python3-Werkzeug \
        rdma-core-devel \
        snappy-devel \
        socat \
        sudo \
        systemd \
        systemd-rpm-macros \
        udev \
        util-linux \
        valgrind-devel \
        which \
        xfsprogs \
        xfsprogs-devel \
        xmlsec1-devel \
        xmlsec1-openssl-devel \
        xmlstarlet \
        yasm

# # python3 doesn't install a python binary in the path, so make one
# # otherwise cmake is unhappy
# RUN ln -sf python3 /usr/bin/python

# Allow any user to sudo
RUN echo 'ALL ALL=NOPASSWD: ALL' >> /etc/sudoers

RUN mkdir -p /src/ceph && chmod -R 777 /src
WORKDIR /src

# Copy our build script to the container so we can run it
COPY build-upstream.sh /src
