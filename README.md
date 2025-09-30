## Standalone startup-server alpine build

```shell
# alpine
docker buildx build -f alpine.Dockerfile \
  --platform linux/amd64 \
  --output type=local,dest=. \
  --target export-binary \
  ./
  
  
# ubuntu
docker buildx build -f ubuntu.Dockerfile \
  --platform linux/amd64 \
  --output type=local,dest=. \
  --target export-binary \
  ./
```