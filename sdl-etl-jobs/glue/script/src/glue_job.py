import sys

from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

# Initialize the Glue context
args = getResolvedOptions(sys.argv, ['JOB_NAME', 'LANDING_BUCKET', 'PROCESSED_BUCKET', 'DATABASE'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Get bucket names and database from arguments
landing_bucket = args['LANDING_BUCKET']
processed_bucket = args['PROCESSED_BUCKET']
database = args['DATABASE']

# Log the bucket names and database for debugging
print(f"Landing bucket: {landing_bucket}")
print(f"Processed bucket: {processed_bucket}")
print(f"Database: {database}")

# Read data from the Glue Data Catalog
organizations_df = glueContext.create_dynamic_frame.from_catalog(
database=database,
table_name='organizations_json'
)
print("Successfully read organizations data")

memberships_df = glueContext.create_dynamic_frame.from_catalog(
database=database,
table_name='memberships_json'
)
print("Successfully read memberships data")

regions_df = glueContext.create_dynamic_frame.from_catalog(
database=database,
table_name='regions_json'
)
print("Successfully read regions data")

persons_df = glueContext.create_dynamic_frame.from_catalog(
database=database,
table_name='persons_json'
)
print("Successfully read persons data")

# Perform transformation on organizations
applymapping1 = ApplyMapping.apply(
frame=organizations_df,
mappings=[
    ("identifiers", "array", "identifiers", "array"),
    ("other_names", "array", "other_names", "array"),
    ("id", "string", "id", "string"),
    ("classification", "string", "classification", "string"),
    ("name", "string", "name", "string")
]
)
print("Successfully transformed organizations data")

# Perform transformation on memberships
applymapping2 = ApplyMapping.apply(
frame=memberships_df,
mappings=[
    ("id", "string", "membership_id", "string"),
    ("person_id", "string", "person_id", "string"),
    ("organization_id", "string", "organization_id", "string"),
    ("role", "string", "role", "string"),
    ("start_date", "string", "start_date", "string"),
    ("end_date", "string", "end_date", "string")
]
)
print("Successfully transformed memberships data")

# Perform transformation on regions
applymapping3 = ApplyMapping.apply(
frame=regions_df,
mappings=[
    ("id", "string", "region_id", "string"),
    ("name", "string", "region_name", "string"),
    ("country", "string", "country", "string")
]
)
print("Successfully transformed regions data")

# Perform transformation on regions
applymapping4 = ApplyMapping.apply(
frame=persons_df,
mappings=[
    ("family_name", "string", "family_name", "string"),
    ("name", "string", "name", "string"),
    ("links", "array", "links", "array"),
    ("gender", "string", "gender", "string"),
    ("image", "string", "image", "string"),
    ("identifiers", "array", "identifiers", "array")
]
)
print("Successfully transformed persons data")

# Write the transformed organizations data to the processed bucket
datasink1 = glueContext.write_dynamic_frame.from_options(
frame=applymapping1,
connection_type="s3",
connection_options={"path": f"{processed_bucket}/organizations/"},
format="json"
)
print("Successfully wrote organizations data to S3")

# Write the transformed memberships data to the processed bucket
datasink2 = glueContext.write_dynamic_frame.from_options(
frame=applymapping2,
connection_type="s3",
connection_options={"path": f"{processed_bucket}/memberships/"},
format="json"
)
print("Successfully wrote memberships data to S3")

# Write the transformed regions data to the processed bucket
datasink3 = glueContext.write_dynamic_frame.from_options(
frame=applymapping3,
connection_type="s3",
connection_options={"path": f"{processed_bucket}/regions/"},
format="json"
)
print("Successfully wrote regions data to S3")

# Write the transformed persons data to the processed bucket
datasink4 = glueContext.write_dynamic_frame.from_options(
frame=applymapping4,
connection_type="s3",
connection_options={"path": f"{processed_bucket}/persons/"},
format="json"
)
print("Successfully wrote persons data to S3")

job.commit()
print("Job committed successfully")
