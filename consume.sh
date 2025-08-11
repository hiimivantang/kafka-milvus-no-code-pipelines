#!/bin/bash

docker exec broker kafka-console-consumer --bootstrap-server localhost:9092 --topic test_topic --offset "earliest" --partition 0
