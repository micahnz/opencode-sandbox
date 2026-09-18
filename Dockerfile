# syntax=docker/dockerfile:1
ARG BUILD_IMAGE=dhi.io/debian-base:trixie-debian13-dev
ARG RUNTIME_IMAGE=dhi.io/debian-base:trixie-debian13
ARG USER=agent
ARG UID=1000
ARG GID=1000

FROM ${BUILD_IMAGE} AS nix-builder
ARG USER
ARG UID
ARG GID

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        curl \
        git \
        xz-utils \
        passwd \
    && rm -rf /var/lib/apt/lists/*

RUN useradd \
        --uid ${UID} \
        --create-home \
        --shell /bin/bash \
        "${USER}" \
    && mkdir -p /nix \
    && chown -R ${UID}:${GID} /nix /home/${USER}

USER ${USER}

ENV USER=${USER}
ENV HOME=/home/${USER}
ENV PATH=/home/${USER}/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/bin

WORKDIR /home/${USER}

RUN curl --proto '=https' --tlsv1.2 --fail --location \
        https://nixos.org/nix/install \
    | sh -s -- --no-daemon

COPY --chown=${UID}:${GID} nix.conf /home/${USER}/.config/nix/nix.conf

RUN . "$HOME/.nix-profile/etc/profile.d/nix.sh" \
    && nix-channel --add https://nixos.org/channels/nixos-26.05 nixpkgs \
    && nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs-unstable \
    && nix-channel --add https://github.com/nix-community/home-manager/archive/release-26.05.tar.gz home-manager \
    && nix-channel --update

RUN . "$HOME/.nix-profile/etc/profile.d/nix.sh" \
    && nix-shell '<home-manager>' -A install

# Runtime
FROM ${RUNTIME_IMAGE} AS runtime
ARG USER
ARG UID
ARG GID

COPY --from=nix-builder /usr/bin/sed /usr/bin/sed
COPY --from=nix-builder /etc/passwd /etc/passwd
COPY --from=nix-builder /etc/group /etc/group

# default user and home directory from the build image
COPY --from=nix-builder --chown=${UID}:${GID} /nix /nix
COPY --from=nix-builder --chown=${UID}:${GID} /home/${USER} /home/${USER}

USER ${USER}
ENV USER=${USER}
ENV HOME=/home/${USER}
ENV PATH=/home/${USER}/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/bin
WORKDIR /home/${USER}

# entrypoint script
COPY --chown=${UID}:${GID} entrypoint.sh /usr/local/bin/entrypoint.sh

# copy agent documentation and configuration files
COPY --chown=${UID}:${GID} .agents /home/${USER}/.agents
RUN sed -i 's/__USER__/'${USER}'/g' /home/${USER}/.agents/AGENTS.md

# home-manager configuration
COPY --chown=${UID}:${GID} home.nix /home/${USER}/.config/home-manager/home.nix
RUN sed -i 's/__USER__/'${USER}'/g' /home/${USER}/.config/home-manager/home.nix

ENTRYPOINT ["/bin/bash", "/usr/local/bin/entrypoint.sh"]

CMD ["serve"]
