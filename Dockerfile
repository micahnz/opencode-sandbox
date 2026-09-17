# syntax=docker/dockerfile:1
ARG BUILD_IMAGE=dhi.io/debian-base:trixie-debian13-dev
ARG RUNTIME_IMAGE=dhi.io/debian-base:trixie-debian13

FROM ${BUILD_IMAGE} AS nix-builder

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
        --uid 1000 \
        --create-home \
        --shell /bin/bash \
        agent \
    && mkdir -p /nix \
    && chown -R agent:agent /nix /home/agent

USER agent

ENV USER=agent
ENV HOME=/home/agent
ENV PATH=/home/agent/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/bin

WORKDIR /home/agent

RUN curl --proto '=https' --tlsv1.2 --fail --location \
        https://nixos.org/nix/install \
    | sh -s -- --no-daemon

COPY --chown=1000:1000 nix.conf /home/agent/.config/nix/nix.conf

RUN . "$HOME/.nix-profile/etc/profile.d/nix.sh" \
    && nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs \
    && nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager \
    && nix-channel --update

RUN . "$HOME/.nix-profile/etc/profile.d/nix.sh" \
    && nix-shell '<home-manager>' -A install

COPY --chown=1000:1000 home.nix /home/agent/.config/home-manager/home.nix

RUN . "$HOME/.nix-profile/etc/profile.d/nix.sh" \
    && home-manager switch -b backup

# Runtime
FROM ${RUNTIME_IMAGE} AS runtime

USER 1000:1000

ENV USER=agent
ENV HOME=/home/agent
ENV NIX_PATH=nixpkgs=channel:nixpkgs-unstable
ENV PATH=/home/agent/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/bin

WORKDIR /home/agent

# default user and home directory from the build image
COPY --from=nix-builder /etc/passwd /etc/passwd
COPY --from=nix-builder /etc/group /etc/group
COPY --from=nix-builder --chown=1000:1000 /nix /nix
COPY --from=nix-builder --chown=1000:1000 /home/agent /home/agent

# copy agent documentation and configuration files
COPY --chown=1000:1000 AGENTS.md /home/agent/AGENTS.md
COPY --chown=1000:1000 .agents /home/agent/.agents

# entrypoint script
COPY --chown=1000:1000 entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/home/agent/.nix-profile/bin/bash", "/usr/local/bin/entrypoint.sh"]

CMD ["serve"]
