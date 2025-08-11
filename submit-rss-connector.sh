#!/bin/bash

HEADER="Content-Type: application/json"

DATA=$( cat <<EOF
{
  "name":"rss-to-kafka",
  "config":{
    "connector.class":"org.kaliy.kafka.connect.rss.RssSourceConnector",
    "rss.urls": "https://feeds.content.dowjones.io/public/rss/RSSWorldNews",
    "topic": "test_topic",
    "value.converter": "org.apache.kafka.connect.json.JsonConverter",
    "value.converter.schemas.enable": "false",
    "transforms": "flatten,replacefield,TimestampConverter",
    "transforms.flatten.type": "org.apache.kafka.connect.transforms.Flatten\$Value",
    "transforms.flatten.delimiter": "_",
    "transforms.replacefield.type": "org.apache.kafka.connect.transforms.ReplaceField\$Value",
    "transforms.replacefield.exclude": "feed_url,author",
    "transforms.TimestampConverter.type": "org.apache.kafka.connect.transforms.TimestampConverter\$Value",
    "transforms.TimestampConverter.field": "date",
    "transforms.TimestampConverter.unix.precision": "milliseconds",
    "transforms.TimestampConverter.format": "yyyy-MM-dd'T'HH:mm:ss'Z'",
    "transforms.TimestampConverter.target.type": "Timestamp"

  } 
}
EOF
)

curl -X POST -H "${HEADER}" --data "${DATA}" -k http://localhost:8083/connectors
