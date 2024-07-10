import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

## @params: [JOB_NAME]
args = getResolvedOptions(sys.argv, ['JOB_NAME', 'LANDING_BUCKET', 'PROCESSED_BUCKET'])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Reading data from the landing bucket
landing_bucket = args['LANDING_BUCKET']
dyf = glueContext.create_dynamic_frame.from_options(
    "s3", 
    {"paths": [landing_bucket]},
    format="json"
)

# Simple transformation: apply a mapping
mapped_dyf = dyf.apply_mapping(
    [("field1", "string", "field1", "string"),
     ("field2", "string", "field2", "string")]
)

# Writing data to the processed bucket
processed_bucket = args['PROCESSED_BUCKET']
glueContext.write_dynamic_frame.from_options(
    frame = mapped_dyf, 
    connection_type = "s3", 
    connection_options = {"path": processed_bucket},
    format = "json"
)

job.commit()
