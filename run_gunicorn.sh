#!/bin/bash

cd ~/asreview
source pyenv/bin/activate

gunicorn -w 4 -b :8080 --timeout 120 'asreview.webapp.start_flask:create_app()'
