#!/bin/bash 

# Author: Sufyaan Kazi
# Date: May 2018

enableAPIIfNecessary() {
  API_EXISTS=`gcloud services list | grep $1 | wc -l`

  if [ $API_EXISTS -eq 0 ]
  then
    gcloud services enable $1
  fi
}

waitTillPodReady(){
  COUNT=`kubectl get pods | grep $1 | grep Running | wc -l`
  while [ $COUNT -ne $2 ]
  do
    sleep 5
    COUNT=`kubectl get pods | grep $1 | grep Running | wc -l`
  done
}

PROJECT_ID=`gcloud config list project --format "value(core.project)"`
ZONE=europe-west2-b
INSTANCE=opentsdb

#Grab the sample project
git clone https://github.com/GoogleCloudPlatform/opentsdb-bigtable.git
cd opentsdb-bigtable/

#Create the Kubernetes Cluster
gcloud config set compute/zone europe-west2-b
enableAPIIfNecessary container.googleapis.com
gcloud container clusters create opentsdb-cluster --scopes "https://www.googleapis.com/auth/bigtable.admin","https://www.googleapis.com/auth/bigtable.data" --cluster-version latest --node-version latest

# Create the Configmap for OpenTSDB config
sed -i -e 's/REPLACE_WITH_PROJECT/'"$PROJECT_ID"'/g' configmaps/opentsdb-config.yaml
sed -i -e 's/REPLACE_WITH_ZONE/'"$ZONE"'/g' configmaps/opentsdb-config.yaml
sed -i -e 's/REPLACE_WITH_INSTANCE/'"$INSTANCE"'/g' configmaps/opentsdb-config.yaml
kubectl create -f configmaps/opentsdb-config.yaml

# Create OpenTSDB tables in BigTable
enableAPIIfNecessary bigtableadmin.googleapis.com
kubectl create -f jobs/opentsdb-init.yaml
pods=$(kubectl get pods  --show-all --selector=job-name=opentsdb-init \
--output=jsonpath={.items..metadata.name})
sleep 5
kubectl logs $pods

# Create a deployment to write metrics
kubectl create -f deployments/opentsdb-write.yaml
waitTillPodReady opentsdb-write 3

# Create a deployment for reading metrics
kubectl create -f deployments/opentsdb-read.yaml
waitTillPodReady opentsdb-read 3

# Create Services for reading & writing
kubectl create -f services/opentsdb-write.yaml
kubectl create -f services/opentsdb-read.yaml
kubectl get services

# Deploy Heapster to write metrics and Grafana to visualise them
kubectl create -f deployments/heapster.yaml
waitTillPodReady heapster 1
kubectl create -f deployments/grafana.yaml
waitTillPodReady grafana 1


