#!/bin/bash

docker build -t default_host_image -f Dockerfile_host .
docker build -t ansible_image -f Dockerfile_ansible .