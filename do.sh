#!/bin/bash

influxId=$(docker run --rm -d -p 8086:8086 influxdb)
graphiteId=$(docker run --rm -d -p 2003:2003 graphite)
grafanaId=$(docker run --rm -d -p 3000:3000 grafana/grafana)

echo "Sleeping while the containers spool up..." >&2
sleep 10

influxIp=$(docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${influxId})
graphiteIp=$(docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${graphiteId})

curl -XPOST http://localhost:8086/query --data-urlencode "q=CREATE DATABASE db"

dsFile="`uuidgen`"
echo -n '{
  "orgId": 1,
  "name": "Influx Contianer",
  "type": "influxdb",
  "typeLogoUrl": "public/app/plugins/datasource/influxdb/img/influxdb_logo.svg",
  "access": "proxy",
  "url": "http://XXX.XXX.XXX.XXX:8086",
  "password": "",
  "user": "",
  "database": "db",
  "basicAuth": false,
  "basicAuthUser": "",
  "basicAuthPassword": "",
  "withCredentials": false,
  "isDefault": true,
  "jsonData": {
    "keepCookies": [],
    "timeInterval": "0.0001s"
  },
  "secureJsonFields": {},
  "version": 3,
  "readOnly": false
}' | sed "s/XXX.XXX.XXX.XXX/${influxIp}/" > ${dsFile}.json
while [ true ]
do
    curl -XPOST --data-binary @${dsFile}.json --header "Content-Type: applcation/json" http://admin:admin@localhost:3000/api/datasources && break
done
rm ${dsFile}.json
echo

dsFile="`uuidgen`"
echo -n '{
    "id": 1,
    "orgId": 1,
    "name": "Graphite Container",
    "type": "graphite",
    "typeLogoUrl": "public/app/plugins/datasource/graphite/img/graphite_logo.png",
    "access": "proxy",
    "url": "http://XXX.XXX.XXX.XXX",
    "password": "",
    "user": "",
    "database": "",
    "basicAuth": false,
    "isDefault": false,
    "jsonData": {
      "graphiteType": "default",
      "graphiteVersion": "1.1"
    },
    "readOnly": false
  }' | sed "s/XXX.XXX.XXX.XXX/${graphiteIp}/" > ${dsFile}.json
while [ true ]
do
    curl -XPOST --data-binary @${dsFile}.json --header "Content-Type: applcation/json" http://admin:admin@localhost:3000/api/datasources && break
done
rm ${dsFile}.json
