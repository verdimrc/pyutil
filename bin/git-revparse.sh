#!/bin/bash

cd $1
pwd
git rev-parse --short HEAD
git rev-parse HEAD
git show -s --format='%an%n%ad%n%s'
