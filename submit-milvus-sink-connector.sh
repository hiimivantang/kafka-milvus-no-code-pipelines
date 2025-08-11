#!/bin/bash

HEADER="Content-Type: application/json"

DATA=$( cat <<EOF
{
  "name":"kafka-to-milvus",
  "config":{
    "connector.class":"com.milvus.io.kafka.MilvusSinkConnector",
    "public.endpoint":"http://standalone:19530",
    "collection.name":"realtime_embeddings",
    "topics":"test_topic",
    "token":"root:Milvus",
    "value.converter": "org.apache.kafka.connect.json.JsonConverter",
    "value.converter.schemas.enable": "false"
  } 
}
EOF
)

curl -X POST -H "${HEADER}" --data "${DATA}" -k http://localhost:8083/connectors
