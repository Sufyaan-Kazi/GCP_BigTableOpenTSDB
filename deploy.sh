#!/bin/bash 

# Author: Sufyaan Kazi
# Date: May 2018
# Purpose: To run this Self Paced Course: https://google.qwiklabs.com/focuses/163?parent=catalog

#Load in vars and common functions
. ./vars.properties
. ./common.sh

# Start
#. ./cleanup.sh

PROJECT_ID=`gcloud config list project --format "value(core.project)"`

enableAPIIfNecessary() {
  API_EXISTS=`gcloud services list | grep $1 | wc -l`

  if [ $API_EXISTS -eq 0 ]
  then
    gcloud services enable $1
  fi
}

#enableAPIIfNecessary compute.googleapis.com
gcloud config set project $PROJECT_ID
gcloud config set compute/zone $ZONE

gcloud beta bigtable instances create OpenTSDB --instance-type=Development
