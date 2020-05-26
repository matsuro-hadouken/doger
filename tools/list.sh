#!/bin/bash

# List all running containers on the system

docker container ls --format 'table {{.Names}}\t{{.Status}}'
