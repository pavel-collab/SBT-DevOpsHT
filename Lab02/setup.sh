#!/bin/bash

docker rm $(docker ps -a -q)
docker build -t python_udp_servers_imagetest -f Dockerfile_server .
docker build -t python_udp_client_image -f Dockerfile_client .
docker build -t ansible_image -f Dockerfile_ansible .