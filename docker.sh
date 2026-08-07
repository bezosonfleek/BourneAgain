#!/usr/bin/env bash

docker inspect -f '{{ .Name }}' $(docker ps -qa)
