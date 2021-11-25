#!/bin/bash

cd ~/asreview
source pyenv/bin/activate

python -m asreview lab --ip 0.0.0.0 --port 8080
