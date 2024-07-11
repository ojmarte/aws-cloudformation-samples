import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

# Initialize the Glue context
args = getResolvedOptions(sys.argv, ['JOB_NAME'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Define the source and target locations
org = args.get("pOrg", "default-org")
domain = args.get("pDomain", "default-domain")
environment = args.get("pEnvironment", "dev")

landing_bucket = f's3://{org}-{domain}-{environment}-landing-bucket'
processed_bucket = f's3://{org}-{domain}-{environment}-processed-bucket'

# Read data from the landing bucket
datasource0 = glueContext.create_dynamic_frame.from_options(
    connection_type="s3",
    connection_options={"paths": [landing_bucket]},
    format="json"
)

# Perform transformation
applymapping1 = ApplyMapping.apply(
    frame=datasource0,
    mappings=[("col0", "string", "col0", "string"),
              ("col1", "string", "col1", "string"),
              ("col2", "string", "col2", "string")]
)

# Write the transformed data to the processed bucket
datasink2 = glueContext.write_dynamic_frame.from_options(
    frame=applymapping1,
    connection_type="s3",
    connection_options={"path": processed_bucket},
    format="json"
)

job.commit()
