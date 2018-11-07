#!/bin/bash

function usage {
	echo "Usage: tpcds-setup.sh scale_factor [temp_directory]"
	exit 1
}

function runcommand {
	if [ "X$DEBUG_SCRIPT" != "X" ]; then
		$1
	else
		$1 2>/dev/null
	fi
}

which hive > /dev/null 2>&1
if [ $? -ne 0 ]; then
	echo "Script must be run where Hive is installed"
	exit 1
fi
# Tables in the TPC-DS schema.
DIMS="date_dim time_dim item customer customer_demographics household_demographics customer_address store promotion warehouse ship_mode reason income_band call_center web_page catalog_page web_site"
FACTS="inventory web_returns catalog_returns store_returns web_sales catalog_sales store_sales"

# Get the parameters.
SCALE=$1
DIR=$2
if [ "X$BUCKET_DATA" != "X" ]; then
	BUCKETS=13
	RETURN_BUCKETS=13
else
	BUCKETS=1
	RETURN_BUCKETS=1
fi
if [ "X$DEBUG_SCRIPT" != "X" ]; then
	set -x
fi

# Sanity checking.
if [ X"$SCALE" = "X" ]; then
	usage
fi
if [ $SCALE -eq 1 ]; then
	echo "Scale factor must be greater than 1"
	exit 1
fi

FORMAT=orc
DATABASE=tpcds_bin_partitioned_${FORMAT}_${SCALE}
DIR=/apps/hive/warehouse/${DATABASE}.db

echo "Optimizing table $t ($i/$total)."
COMMAND="hive -i settings/load-partitioned.sql -f ddl-tpcds/fix/alltables.sql \
    -d DB=${DATABASE} -d LOCATION=${DIR} \
    -d SCALE=${SCALE} \
    -d FILE=${FORMAT}"
runcommand "$COMMAND"
if [ $? -ne 0 ]; then
    echo "Command failed, try 'export DEBUG_SCRIPT=ON' and re-running"
    exit 1
fi
