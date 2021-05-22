#!/usr/bin/env bash
set -o pipefail -o errtrace -o errexit

clean_up_on_err() {
    echo "Error occurred: line $(caller 0)" >&2
    if [ ! -z "${bid+x}" ]; then
        echo "Removing buildah container ${bid}..."
        buildah rm "${bid}"
    fi
}

trap clean_up_on_err ERR

bid=$(buildah from docker.io/debian:buster)
buildah config --env DEBIAN_FRONTEND=noninteractive "${bid}"
buildah run "${bid}" apt update
buildah run "${bid}" apt install -y --no-install-recommends \
    systemd \
    systemd-sysv \
    procps
buildah run "${bid}" bash -c 'find /var/cache/apt -type f -print0 | \
    xargs --null rm -f'
buildah run "${bid}" bash -c 'find /var/lib/apt/lists -type f -print0 | \
    xargs --null rm -f'
buildah run "${bid}" \
    rm -f /lib/systemd/system/multi-user.target.wants/getty.target
buildah config --cmd="" "${bid}"
buildah config --entrypoint '["/lib/systemd/systemd"]' "${bid}"
buildah config --env DEBIAN_FRONTEND- "${bid}"
buildah commit "${bid}" debian-10-systemd

buildah rm "${bid}"

exit 0
