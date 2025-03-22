#!/bin/bash
set -euo pipefail

# -- Build Apache Spark Standalone Cluster Docker Images --

# ----------------------------------------------------------------------------------------------------------------------
# -- Variables ---------------------------------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------------------------------------------

BUILD_DATE="$(date -u +'%Y-%m-%d')"
SCALA_VERSION="2.12"
SPARK_VERSION="3.4.1"
HADOOP_VERSION="3"
DELTA_SPARK_VERSION="2.4.0"
DELTALAKE_VERSION="0.10.0"
JUPYTERLAB_VERSION="4.0.2"
PANDAS_VERSION="2.0.1"
DELTA_PACKAGE_VERSION="delta-core_2.12:2.4.0"
SPARK_VERSION_MAJOR=${SPARK_VERSION:0:1}
SPARK_XML_PACKAGE_VERSION="spark-xml_2.12:0.16.0"
SPARKSQL_MAGIC_VERSION="0.0.3"
KAFKA_PYTHON_VERSION="2.0.2"
JAVA_IMAGE_TAG="17-jre-jammy" # Update

# ----------------------------------------------------------------------------------------------------------------------
# -- Functions ---------------------------------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------------------------------------------
# add build-arg java_image_tag="${JAVA_IMAGE_TAG}

function stopAndRemoveContainerByName() {
  local name=$1
  local container_id
  container_id=$(docker ps -aqf "name=$name")
  if [[ -n "$container_id" ]]; then
    docker stop "$container_id"
    docker rm "$container_id"
  fi
}

function cleanContainers() {
  echo "[INFO] Cleaning containers..."

  stopAndRemoveContainerByName jupyterlab
  stopAndRemoveContainerByName spark-worker
  stopAndRemoveContainerByName spark-master
  stopAndRemoveContainerByName spark-base
  stopAndRemoveContainerByName base
}

function removeImageByName() {
  local name=$1
  local image_id
  image_id=$(docker images | grep -m 1 "$name" | awk '{print $3}')
  if [[ -n "$image_id" ]]; then
    docker rmi -f "$image_id"
  fi
}

function cleanImages() {
  echo "[INFO] Cleaning images..."

  removeImageByName jupyterlab
  removeImageByName spark-worker
  removeImageByName spark-master
  removeImageByName spark-base
  removeImageByName base
}

function cleanVolume() {
  echo "[INFO] Cleaning volume..."
  docker volume rm "distributed-file-system" 2>/dev/null || echo "No volume to remove"
}

function buildImages() {
  echo "[INFO] Building Docker images..."

  docker build \
    --build-arg build_date="${BUILD_DATE}" \
    --build-arg scala_version="${SCALA_VERSION}" \
    --build-arg delta_spark_version="${DELTA_SPARK_VERSION}" \
    --build-arg deltalake_version="${DELTALAKE_VERSION}" \
    --build-arg pandas_version="${PANDAS_VERSION}" \
    --build-arg java_image_tag="${JAVA_IMAGE_TAG}" \
    -f docker/base/Dockerfile \
    -t base:latest .

  docker build \
    --build-arg build_date="${BUILD_DATE}" \
    --build-arg scala_version="${SCALA_VERSION}" \
    --build-arg delta_spark_version="${DELTA_SPARK_VERSION}" \
    --build-arg deltalake_version="${DELTALAKE_VERSION}" \
    --build-arg pandas_version="${PANDAS_VERSION}" \
    --build-arg spark_version="${SPARK_VERSION}" \
    --build-arg hadoop_version="${HADOOP_VERSION}" \
    --build-arg delta_package_version="${DELTA_PACKAGE_VERSION}" \
    --build-arg spark_xml_package_version="${SPARK_XML_PACKAGE_VERSION}" \
    --build-arg java_image_tag="${JAVA_IMAGE_TAG}" \
    -f docker/spark-base/Dockerfile \
    -t spark-base:${SPARK_VERSION} .

  docker build \
    --build-arg build_date="${BUILD_DATE}" \
    --build-arg spark_version="${SPARK_VERSION}" \
    --build-arg java_image_tag="${JAVA_IMAGE_TAG}" \
    -f docker/spark-master/Dockerfile \
    -t spark-master:${SPARK_VERSION} .

  docker build \
    --build-arg build_date="${BUILD_DATE}" \
    --build-arg spark_version="${SPARK_VERSION}" \
    --build-arg java_image_tag="${JAVA_IMAGE_TAG}" \
    -f docker/spark-worker/Dockerfile \
    -t spark-worker:${SPARK_VERSION} .

  docker build \
    --build-arg build_date="${BUILD_DATE}" \
    --build-arg scala_version="${SCALA_VERSION}" \
    --build-arg delta_spark_version="${DELTA_SPARK_VERSION}" \
    --build-arg deltalake_version="${DELTALAKE_VERSION}" \
    --build-arg pandas_version="${PANDAS_VERSION}" \
    --build-arg spark_version="${SPARK_VERSION}" \
    --build-arg jupyterlab_version="${JUPYTERLAB_VERSION}" \
    --build-arg sparksql_magic_version="${SPARKSQL_MAGIC_VERSION}" \
    --build-arg kafka_python_version="${KAFKA_PYTHON_VERSION}" \
    --build-arg java_image_tag="${JAVA_IMAGE_TAG}" \
    -f docker/jupyterlab/Dockerfile \
    -t jupyterlab:${JUPYTERLAB_VERSION}-spark-${SPARK_VERSION} .
}

# ----------------------------------------------------------------------------------------------------------------------
# -- Main Execution ----------------------------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------------------------------------------

cleanContainers
cleanImages
cleanVolume
buildImages

