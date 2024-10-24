Build image
```
docker build -t crc32-checksum-application .
```

Push built image to the docker-regestry
```
docker tag <local image id> <docker-regestry login>/<rep name>:<image name>
docker login -u <login> -p <password>
docker push <docker-regestry login>/<rep name>:<image name>
```

Now docker prebuilt docker image is on the docker-registry and you can pull it simple
```
docker pull fishsword/crc32-checksum:crc32-daemon
```

You will get buit image, with compiled application that you can get from the container or use it inside the container.