# --------------------------------------------
# PowerShell Script: build.ps1
# --------------------------------------------

# Stop on error
$ErrorActionPreference = "Stop"

# Variables
$BUILD_DATE = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd")
$SCALA_VERSION = "2.12"
$SPARK_VERSION = "3.4.1"
$HADOOP_VERSION = "3"
$DELTA_SPARK_VERSION = "2.4.0"
$DELTALAKE_VERSION = "0.10.0"
$JUPYTERLAB_VERSION = "4.0.2"
$PANDAS_VERSION = "2.0.1"
$DELTA_PACKAGE_VERSION = "delta-core_2.12:2.4.0"
$SPARK_VERSION_MAJOR = $SPARK_VERSION.Substring(0,1)
$SPARK_XML_PACKAGE_VERSION = "spark-xml_2.12:0.16.0"
$SPARKSQL_MAGIC_VERSION = "0.0.3"
$KAFKA_PYTHON_VERSION = "2.0.2"
$JAVA_IMAGE_TAG = "17-jre-jammy"

function StopAndRemoveContainerByName($name) {
    $container = docker ps -aqf "name=$name"
    if ($container) {
        docker stop $container | Out-Null
        docker rm $container | Out-Null
    }
}

function CleanContainers() {
    Write-Host "[INFO] Cleaning containers..."
    StopAndRemoveContainerByName "jupyterlab"
    StopAndRemoveContainerByName "spark-worker"
    StopAndRemoveContainerByName "spark-master"
    StopAndRemoveContainerByName "spark-base"
    StopAndRemoveContainerByName "base"
}

function RemoveImageByName($name) {
    $image = docker images --format "{{.Repository}}:{{.Tag}} {{.ID}}" | Where-Object { $_ -match $name } | Select-Object -First 1
    if ($image) {
        $id = $image.Split(" ")[1]
        docker rmi -f $id | Out-Null
    }
}

function CleanImages() {
    Write-Host "[INFO] Cleaning images..."
    RemoveImageByName "jupyterlab"
    RemoveImageByName "spark-worker"
    RemoveImageByName "spark-master"
    RemoveImageByName "spark-base" 
    RemoveImageByName "base"
}

function CleanVolume() {
    Write-Host "[INFO] Cleaning volume..."
    try {
        docker volume rm "distributed-file-system" | Out-Null
    } catch {
        Write-Host "No volume to remove or already removed"
    }
}

function BuildImages() {
    Write-Host "[INFO] Building Docker images..."

    docker build `
        --build-arg build_date=$BUILD_DATE `
        --build-arg scala_version=$SCALA_VERSION `
        --build-arg delta_spark_version=$DELTA_SPARK_VERSION `
        --build-arg deltalake_version=$DELTALAKE_VERSION `
        --build-arg pandas_version=$PANDAS_VERSION `
        --build-arg java_image_tag=$JAVA_IMAGE_TAG `
        -f docker/base/Dockerfile `
        -t base:latest .

    docker build `
        --build-arg build_date=$BUILD_DATE `
        --build-arg scala_version=$SCALA_VERSION `
        --build-arg delta_spark_version=$DELTA_SPARK_VERSION `
        --build-arg deltalake_version=$DELTALAKE_VERSION `
        --build-arg pandas_version=$PANDAS_VERSION `
        --build-arg spark_version=$SPARK_VERSION `
        --build-arg hadoop_version=$HADOOP_VERSION `
        --build-arg delta_package_version=$DELTA_PACKAGE_VERSION `
        --build-arg spark_xml_package_version=$SPARK_XML_PACKAGE_VERSION `
        --build-arg java_image_tag=$JAVA_IMAGE_TAG `
        -f docker/spark-base/Dockerfile `
        -t spark-base:$SPARK_VERSION .

    docker build `
        --build-arg build_date=$BUILD_DATE `
        --build-arg spark_version=$SPARK_VERSION `
        --build-arg java_image_tag=$JAVA_IMAGE_TAG `
        -f docker/spark-master/Dockerfile `
        -t spark-master:$SPARK_VERSION .

    docker build `
        --build-arg build_date=$BUILD_DATE `
        --build-arg spark_version=$SPARK_VERSION `
        --build-arg java_image_tag=$JAVA_IMAGE_TAG `
        -f docker/spark-worker/Dockerfile `
        -t spark-worker:$SPARK_VERSION .

    docker build `
        --build-arg build_date=$BUILD_DATE `
        --build-arg scala_version=$SCALA_VERSION `
        --build-arg delta_spark_version=$DELTA_SPARK_VERSION `
        --build-arg deltalake_version=$DELTALAKE_VERSION `
        --build-arg pandas_version=$PANDAS_VERSION `
        --build-arg spark_version=$SPARK_VERSION `
        --build-arg jupyterlab_version=$JUPYTERLAB_VERSION `
        --build-arg sparksql_magic_version=$SPARKSQL_MAGIC_VERSION `
        --build-arg kafka_python_version=$KAFKA_PYTHON_VERSION `
        --build-arg java_image_tag=$JAVA_IMAGE_TAG `
        -f docker/jupyterlab/Dockerfile `
        -t jupyterlab:$JUPYTERLAB_VERSION-spark-$SPARK_VERSION .
}

# --------------------------------------------
# Main Execution
# --------------------------------------------

CleanContainers
CleanImages
CleanVolume
BuildImages
