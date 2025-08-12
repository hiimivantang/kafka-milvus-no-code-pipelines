from pymilvus import MilvusClient, DataType, Function, FunctionType

client = MilvusClient(
    uri="http://localhost:19530",
    token="root:Milvus"
)

schema = client.create_schema()

schema.add_field("id", DataType.VARCHAR, is_primary=True, auto_id=False, max_length=1000)
schema.add_field("content", DataType.VARCHAR, max_length=9000)
schema.add_field("date", DataType.INT64)
schema.add_field("feed_title", DataType.VARCHAR, max_length=1000)
schema.add_field("link", DataType.VARCHAR, max_length=2000)
schema.add_field("title", DataType.VARCHAR, max_length=2000)
schema.add_field("content_dense", DataType.FLOAT_VECTOR, dim=1536)
index_params = client.prepare_index_params()

index_params.add_index(
    field_name="content_dense", 
    index_type="AUTOINDEX",
    metric_type="COSINE"
)

text_embedding_function = Function(
    name="openai_embedding",                        # Unique identifier for this embedding function
    function_type=FunctionType.TEXTEMBEDDING,       # Type of embedding function
    input_field_names=["content"],                 # Scalar field to embed
    output_field_names=["content_dense"],                   # Vector field to store embeddings
    params={                                        # Provider-specific configuration (highest priority)
        "provider": "openai",                       # Embedding model provider
        "model_name": "text-embedding-3-small",     # Embedding model
        # Optional parameters:
        # "credential": "apikey_dev",               # Optional: Credential label specified in milvus.yaml
        # "dim": "1536",                            # Optional: Shorten the output vector dimension
        # "user": "user123"                         # Optional: identifier for API tracking
    }
)

schema.add_function(text_embedding_function)

client.create_collection(collection_name="realtime_embeddings", 
                         schema=schema, 
                         index_params=index_params)
client.load_collection("realtime_embeddings")
