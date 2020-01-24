#!/bin/bash 
pushd $(dirname $0)
mvn -Pgenerate-target -f $1/pom.xml clean verify
popd
