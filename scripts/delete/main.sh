#!/bin/bash

./delete-sdl-monitoring.sh
if [ $? -ne 0 ]; then
  echo "Monitoring script failed. Exiting."
  exit 1
fi

# Run the ETL script
./delete-sdl-etl.sh
if [ $? -ne 0 ]; then
  echo "ETL script failed. Exiting."
  exit 1
fi

# Run the foundation script
./delete-sdl-foundation.sh
if [ $? -ne 0 ]; then
  echo "Foundation script failed. Exiting."
  exit 1
fi

echo "All scripts ran successfully."
