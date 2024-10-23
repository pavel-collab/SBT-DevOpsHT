Build image
```
docker build -t CRC32-checksum-application .
```

Push built image to the docker-regestry
```
docker tag <local image id> <docker-regestry login>/<rep name>:<image name>
docker login -u <login> -p <password>
docker push <docker-regestry login>/<rep name>:<image name>
```