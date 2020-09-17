#!/bin/bash

[ $# -ne 2 ] && echo -e "Usage: upkern.sh <alert_type> x.y.z-p <type>\ntype: generic|aws|oem|gcp|gke|lowlatency|kvm|euclid|azure|azure-edge|" && exit -1

img=linux-image-$1-$2
img_extra=linux-image-extra-$1-$2

#sudo apt-get -y install linux-image-4.8.0-41-generic linux-image-extra-4.8.0-41-generic
