#!/bin/bash

docker-compose down
docker system prune -a
docker rmi $(docker images -a -q)
docker rm $(docker ps -a -f status=exited -q)
docker volume prune
