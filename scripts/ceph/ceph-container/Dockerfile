# Default: start with the upstream daemon-base container which is the ceph/ceph container's source
ARG CEPH_BASE_IMAGE=quay.io/ceph/daemon-base
FROM quay.io/ceph/daemon-base

RUN mkdir /src

# Copy python files into the Ceph container
COPY .python-files/ /src/ceph/python/
COPY .mgr-mod-files /src/ceph/mgr-mod/
RUN set -Eex ; \
    if   which python;  then python=python  ; \
    elif which python3; then python=python3 ; \
    elif which python2; then python=python2 ; \
    fi ; echo python=$python ; \
    for dir in /src/ceph/python/* ; do \
        echo $dir ; \
        pushd $dir ; \
        $python setup.py install --root=/ --single-version-externally-managed --force ; \
        popd ; \
    done
RUN cp --verbose --recursive --force /src/ceph/mgr-mod/* /usr/share/ceph/mgr/.

# TODO: Copy Ceph binaries into the Ceph container
