```
sudo docker-compose -p 'ansible_proj' up --force-recreate
```

Stop all of the running containers
```
docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)
```