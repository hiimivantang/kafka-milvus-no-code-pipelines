# Real-time GenAI Pipeline with Kafka and Milvus

A real-time data pipeline that ingests RSS feeds through Kafka Connect, processes them with built-in embedding functions, and stores them in Milvus vector database for GenAI applications.

## Architecture

This project creates a no-code data pipeline that:
- Ingests RSS feeds using Kafka Connect RSS Source Connector
- Processes data through Kafka topics
- Automatically generates embeddings using OpenAI's text-embedding-3-small model
- Stores structured data and embeddings in Milvus vector database

## Prerequisites

- Docker and Docker Compose
- Python 3.x with pymilvus library
- Confluent CLI (for topic creation)

## Getting Started

### 1. Start Docker Services

Navigate to the `cp-all-in-one/` directory and spin up all services:

```bash
cd cp-all-in-one/
docker-compose up -d
```

This will start:
- Kafka broker
- Schema Registry  
- Kafka Connect
- Control Center
- Milvus vector database
- MinIO (object storage for Milvus)

### 2. Create Kafka Topic

Run the topic creation script:

```bash
./create_topic.sh
```

This creates a `test_topic` for RSS feed data.

### 3. Set Up Milvus Collection

Create the Milvus collection with schema and embedding functions:

```bash
python create-milvus-collection.py
```

This script:
- Creates a collection called `realtime_embeddings`
- Defines fields for RSS data (title, content, date, etc.)
- Sets up OpenAI embedding function for automatic text vectorization
- Configures vector index for similarity search

### 4. Deploy Connectors

Start the RSS source connector:

```bash
./submit-rss-connector.sh
```

Then deploy the Milvus sink connector:

```bash
./submit-milvus-sink-connector.sh
```

## Data Flow

1. **RSS Ingestion**: RSS connector fetches news from Dow Jones RSS feed
2. **Data Processing**: Kafka transforms flatten and clean the data
3. **Embedding Generation**: Milvus automatically generates embeddings from content
4. **Vector Storage**: Data and embeddings stored in Milvus for similarity search

## Key Components

- **RSS Source Connector**: Fetches from `https://feeds.content.dowjones.io/public/rss/RSSWorldNews`
- **Milvus Sink Connector**: Streams data from Kafka to Milvus
- **Vector Database**: Stores text embeddings for semantic search
- **Embedding Function**: OpenAI text-embedding-3-small for 1536-dimensional vectors

## Connector Configurations

### RSS Source Connector (`submit-rss-connector.sh`)

The RSS source connector uses a declarative JSON configuration that defines data ingestion and transformation:

#### Basic Configuration
```json
{
  "name": "rss-to-kafka",
  "connector.class": "org.kaliy.kafka.connect.rss.RssSourceConnector",
  "rss.urls": "https://feeds.content.dowjones.io/public/rss/RSSWorldNews",
  "topic": "test_topic"
}
```

- **`name`**: Unique identifier for the connector instance
- **`connector.class`**: Java class implementing RSS source functionality
- **`rss.urls`**: Target RSS feed (Dow Jones World News)
- **`topic`**: Destination Kafka topic for RSS data

#### Data Serialization
```json
{
  "value.converter": "org.apache.kafka.connect.json.JsonConverter",
  "value.converter.schemas.enable": "false"
}
```

- **`value.converter`**: Serializes RSS data as JSON messages
- **`schemas.enable: false`**: Disables schema registry, sends raw JSON

#### Transformation Pipeline
The connector applies three sequential transformations:

```json
{
  "transforms": "flatten,replacefield,TimestampConverter"
}
```

**1. Flatten Transform**
```json
{
  "transforms.flatten.type": "org.apache.kafka.connect.transforms.Flatten$Value",
  "transforms.flatten.delimiter": "_"
}
```
- Flattens nested RSS JSON structures
- Uses underscore delimiter (`feed.title` → `feed_title`)
- Essential for handling complex RSS/XML hierarchies

**2. ReplaceField Transform**
```json
{
  "transforms.replacefield.type": "org.apache.kafka.connect.transforms.ReplaceField$Value",
  "transforms.replacefield.exclude": "feed_url,author"
}
```
- Removes unnecessary fields (`feed_url`, `author`)
- Reduces message size and focuses on relevant content
- Optimizes downstream storage and processing

**3. TimestampConverter Transform**
```json
{
  "transforms.TimestampConverter.type": "org.apache.kafka.connect.transforms.TimestampConverter$Value",
  "transforms.TimestampConverter.field": "date",
  "transforms.TimestampConverter.format": "yyyy-MM-dd'T'HH:mm:ss'Z'",
  "transforms.TimestampConverter.target.type": "Timestamp"
}
```
- Converts RSS date strings to proper timestamps
- Expects ISO 8601 format from RSS feeds
- Outputs Kafka Connect Timestamp type for compatibility

### Milvus Sink Connector (`submit-milvus-sink-connector.sh`)

The sink connector configuration handles data flow from Kafka to Milvus:

```json
{
  "name": "kafka-to-milvus",
  "connector.class": "com.milvus.io.kafka.MilvusSinkConnector",
  "public.endpoint": "http://standalone:19530",
  "collection.name": "realtime_embeddings",
  "topics": "test_topic",
  "token": "root:Milvus",
  "value.converter": "org.apache.kafka.connect.json.JsonConverter",
  "value.converter.schemas.enable": "false"
}
```

- **`connector.class`**: Official Zilliz/Milvus sink connector
- **`public.endpoint`**: Milvus server endpoint (Docker service name)
- **`collection.name`**: Target collection matching Python schema
- **`topics`**: Source Kafka topic (matches RSS connector output)
- **`token`**: Milvus authentication (username:password format)
- **Data format**: Same JSON converter settings ensure compatibility

### Architecture Benefits

These declarative configurations create a robust data pipeline with:

- **Data Quality**: Transformation chain cleanses and standardizes RSS data
- **Schema Consistency**: Flattening ensures predictable field names for Milvus
- **Temporal Accuracy**: Proper timestamp conversion enables time-based queries
- **Storage Efficiency**: Field exclusion reduces storage overhead
- **Format Compatibility**: Consistent JSON handling across source and sink

## Monitoring

Access Confluent Control Center at `http://localhost:9021` to monitor:
- Kafka topics and messages
- Connector status
- Data throughput

## Configuration

- Milvus endpoint: `http://localhost:19530`
- Kafka broker: `localhost:9092`
- Schema Registry: `http://localhost:8081`

## Usage

Once the pipeline is running, RSS feed data will be continuously:
1. Ingested into Kafka
2. Transformed and cleaned
3. Embedded using OpenAI models
4. Stored in Milvus for vector similarity search

You can then query the Milvus collection for semantic search across news articles.

## Credits

This project builds upon the following open source components:

- [Milvus](https://github.com/milvus-io/milvus) - The vector database that powers semantic search capabilities
- [Confluent Platform All-in-One](https://github.com/confluentinc/cp-all-in-one) - Docker Compose setup for Confluent Platform
- [Zilliz Kafka Connect Milvus](https://github.com/zilliztech/kafka-connect-milvus) - Kafka Connect sink connector for Milvus
- [Kaliy Kafka Connect RSS](https://github.com/kaliy/kafka-connect-rss) - Kafka Connect source connector for RSS feeds
