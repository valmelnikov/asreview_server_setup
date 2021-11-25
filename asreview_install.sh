#!/bin/bash

cd ~
git clone -b http-auth https://github.com/valmelnikov/asreview.git
cd asreview
/opt/rh/rh-python38/root/usr/bin/python3.8 -m venv pyenv
source pyenv/bin/activate
python setup.py install
cd ..
python -m pip uninstall asreview
python -m pip install gunicorn

echo Auth-enabled ASReview is installed. Copy the built react app to `~/asreview/asreview/webapp/build`. E.g. by 'scp -r Documents/asreview/asreview/webapp/build vmelnik@ivi-megameta.science.uva.nl:~/asreview/asreview/webapp/'
