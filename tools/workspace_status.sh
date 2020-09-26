#!/bin/bash -e

echo "STABLE_GIT_COMMIT $(git rev-parse --short HEAD)"
echo "STABLE_GIT_DATE $(TZ=UTC git show --quiet --date='format-local:%Y-%m-%dT%H' --format="%cd")"
echo "AZ_DEV_DF_CLUSTER_NAME dev-cluster-dbk"
echo "AZ_DEV_DF_CLUSTER_PROFILE dev"
