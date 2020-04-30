# Default: start with the upstream daemon-base container which is the ceph/ceph container's source
ARG CEPH_BASE_IMAGE=ceph/daemon-base
FROM ceph/daemon-base

RUN mkdir /src

# Copy python files into the Ceph container
COPY .python-files/ /src/ceph/python/
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

# TODO: Copy Ceph binaries into the Ceph container
