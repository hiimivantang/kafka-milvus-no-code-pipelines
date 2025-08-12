#!/bin/bash

docker run --rm -it --network cp-all-in-one_default apache/kafka /opt/kafka/bin/kafka-topics.sh --create --topic test_topic --bootstrap-server broker:29092
