# opencode-sandbox

Rootless docker sandbox for opencode agents with openchamber, user needs to
match the host so change USER to match.

UID and GID are 1000 by default, change them as well if needed.

NOTE: first start can take a minute while the initial nix cache volumes are filled.

```bash
USER="micah" docker buildx build --build-arg USER=${USER} -t opencode-sandbox:${USER} .
```

```bash
docker volume create opencode-nix
docker volume create opencode-nix-cache
docker volume create opencode-nix-defexpr

export OPENCODE_SERVER_PORT=4096
export OPENCODE_SEVER_PASSWORD="password"

docker run --rm -ti \
  --name opencode \
  --mount type=volume,src=opencode-nix,dst=/nix \
  --mount type=volume,src=opencode-nix-cache,dst=$HOME/.cache/nix \
  --mount type=volume,src=opencode-nix-defexpr,dst=$HOME/.nix-defexpr \
  --mount type=bind,src="$HOME/.config/openchamber",dst=$HOME/.config/openchamber \
  --mount type=bind,src="$HOME/.config/opencode",dst=$HOME/.config/opencode \
  --mount type=bind,src="$HOME/.local/share/opencode",dst=$HOME/.local/share/opencode \
  --mount type=bind,src="$HOME/Projects",dst="$HOME/Projects" \
  --tmpfs /tmp:rw,noexec,nosuid,size=4g \
  --cap-drop=ALL \
  --security-opt=no-new-privileges:true \
  --pids-limit=512 \
  --memory=16g \
  --cpus=4 \
  --init \
  --env OPENCODE_SERVER_PASSWORD="$OPENCODE_SERVER_PASSWORD" \
  --env OPENCODE_HOST=0.0.0.0 \
  --env OPENCODE_PORT=$OPENCODE_SERVER_PORT \
  --publish 127.0.0.1:$OPENCODE_SERVER_PORT:$OPENCODE_SERVER_PORT \
    opencode-sandbox:$USER
```

##

Volumes are unique to user, if user changes you need to clear the nix cache
volumes

```bash
docker volume rm opencode-nix
docker volume rm opencode-nix-cache
docker volume rm opencode-nix-defexpr
```
