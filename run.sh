#!/bin/sh

IMAGE=user_scraper
CONTAINER=user_scraper

docker rm $CONTAINER;
[ -f output/output.json ] && rm output/output.json
[ -d img ] && rm -fr img

docker build -t $IMAGE . &&
docker run -ti --name $CONTAINER $IMAGE &&
docker cp $CONTAINER:/usr/src/app/output/output.json output/output.json &&
docker cp $CONTAINER:/usr/src/app/img/ img/ &&
docker rm $CONTAINER