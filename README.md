## Standalone startup-server alpine build

```shell
docker buildx build -f alpine.Dockerfile \
  --platform linux/amd64 \
  --output type=local,dest=. \
  --target export-binary \
  ./
```