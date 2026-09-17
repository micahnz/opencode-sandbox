# opencode-sandbox

Rootless docker sandbox for opencode agents

```bash
docker buildx build -t opencode-sandbox:latest .
```

```bash
docker volume create opencode-nix
docker volume create opencode-nix-cache
docker volume create opencode-nix-defexpr

docker run --rm -it \
  --name opencode \
  --mount type=volume,src=opencode-nix,dst=/nix \
  --mount type=volume,src=opencode-nix-cache,dst=/home/agent/.cache/nix \
  --mount type=volume,src=opencode-nix-defexpr,dst=/home/agent/.nix-defexpr \
  --mount type=bind,src="$HOME/.config/opencode",dst=/home/agent/.config/opencode \
  --mount type=bind,src="$HOME/.local/share/opencode",dst=/home/agent/.local/share/opencode \
  --mount type=bind,src="$HOME/Projects",dst=/home/agent/Projects \
  --tmpfs /tmp:rw,noexec,nosuid,size=4g \
  --cap-drop=ALL \
  --security-opt=no-new-privileges:true \
  --pids-limit=512 \
  --memory=16g \
  --cpus=4 \
  --init \
  --env OPENCODE_SERVER_PASSWORD="password" \
  --env OPENCODE_HOST=0.0.0.0 \
  --env OPENCODE_PORT=4096 \
  --publish 127.0.0.1:4096 \
  opencode-sandbox:latest
```
