#!/bin/sh

cd /gpfs/group/ebf11/default/RISE_NEID/data/solar_L1/v1.0.0/
tar -czf /archive/ebf11/default/RISE_NEID/solar_L1/v1.0.0/$1.tar.gz $1
rm -rf $1 
