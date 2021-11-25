# ASReview server setup for MegaMeta study

The repository is part of the so-called, Mega-Meta study on reviewing factors contributing to substance use, anxiety, and depressive disorders. The study protocol has been pre-registered at [Prospero](https://www.crd.york.ac.uk/prospero/display_record.php?ID=CRD42021266297). The current repository contains the procedure for screening the records identified in the search as described by [Brouwer et al (2021)](https://osf.io/m5uhy/). 

The screening was conducted in the software ASReview ([Van de Schoot et al., 2020](https://www.nature.com/articles/s42256-020-00287-7) using the protocol as described in [Hofstee et al. (2021)](https://osf.io/3znar/). The server installation is described in [Melnikov (2021)](https://github.com/valmelnikov/asreview_server_setup), training of the hyperparameters for the CNN-model is described by [Tijema et al (2021)](https://github.com/asreview/paper-megameta-hyperparameter-training), and the post-processing is described by [van de Brand et al., 2021][6]. The data can be found on DANS [LINK NEEDED].


This repo contains information on how the ASReview server was set up for MegaMeta study.

## Description of the Virtual Machine

* Virtual Machine is provided by the [Faculty of Science, University of Amsterdam](https://medewerker.uva.nl/fnwi/shared-content-secured/medewerkersites/fnwi/en/az/ict-services-science/virtual-machines/virtual-machines.html). 
* At the beginning it is 'large' machine with 4 CPUs, 8Gb RAM and 10Gb SSD
* There are no root or super-user privileges, so much of a configuration was done through ICT services representative. This included:
  * Setting up the hostname `ivi-megameta.science.uva.nl`
  * Setting up Nginx to work with SSL and forward the requests coming to 443 (HTTPS) port to whatever process listening on 8080 (HTTP) port. 
  * This seamless use of HTTPS is a good thing, since we are using a basic HTTP-Auth mechanism (described later), which does not have man-in-the-middle protection by itself, so HTTPS protects the password sent openly from being easily read by a third-party.
  * Setting up the service of the ASReview server for it to start with a system startup and being easily stopped and started and queried for the status.
* Machine can only be accessed from within UvA network, so UvA account and VPN is required.
* Log-in to the machine is done via SSH via 
  ```sh
  ssh vmelnik@ivi-megameta.science.uva.nl
  ```
* The home directory in which all the files are stored is `/home/vmelnik/`

## Setup of the ASReview
ASReview was cloned into `~/asreview/` with the command
```sh
mkdir ~/asreview
cd ~/asreview
git clone -b http-auth https://github.com/valmelnikov/asreview.git
```
Python 3.8 virtual environment was created at `~/asreview/` and activated through
```sh
/opt/rh/rh-python38/root/usr/bin/python3.8 -m venv pyenv
source pyenv/bin/activate
```
ASReview dependencies were installed through
```sh
python setup.py install
```
Then the package was removed with
```sh
cd ~
python -m pip uninstall asreview
```
Gunicorn was installed
```sh
python -m pip install gunicorn
```
The React app was built from the same repository on a local machine (due to unavailability of NPM on VM)
```sh
# On a local machine. Basically the commands from /path/to/asreview/asreview/webapp/compile_assets.sh
cd /path/to/asreview/asreview/webapp
npm install
npm run-script build

# Copying to VM
scp -r /path/to/asreview/asreview/webapp/build vmelnik@ivi-megameta.science.uva.nl:/home/vmelnik/asreview/asreview/webapp/
```

In the easiest scenario the setup can be checked through running (while `~/asreview/pyenv` is activated)
```sh
cd ~/asreview
source asreview/bin/activate
python -m asreview lab --port 8080
```
which is what is written in `~/run_asreview.sh`

The unicorn-served production scenario is invoked as follows:
```sh
cd ~/asreview
source asreview/bin/activate
gunicorn -w 4 -b :8080 --timeout 120 'asreview.webapp.start_flask:create_app()'
```
Where `-w 4` stands for 4 worker processes matching the number of CPUs. These commands are the contents of `~/run_gunicorn.sh`. Similar script is used to define the gunicorn service
```ini
ExecStart=/home/vmelnik/asreview/pyenv/bin/gunicorn -w 4 -b :8080 --timeout 120 'asreview.webapp.start_flask:create_app()'
```
And then the service is operated with the following commands:
```sh
sudo /usr/sbin/service vmelnik-gunicorn stop
sudo /usr/sbin/service vmelnik-gunicorn start
sudo /usr/sbin/service vmelnik-gunicorn status
```

### Important notes
* Initial setting up of the project in ASReview only works with `asreview lab` command, not gunicorn server. Most probably it is because important declarations for file readers are made when invoking `asreview lab`, but not when directly asking Flask app from `start_flask.py`.
* Maximum file size setting of Nginx was increased to 500 Mb.

## Setting up passwords
The branch `http-auth`, from which the repository was cloned, was implemented to make HTTP-Auth possible to add another level of protection and enable project-locking functionality (to guarantee that no project is reviewed by more than one reviewer simultaneously).

The password for the user `user1` is set (for the new user) and changed (for the existing user) with the command:
```sh
cd ~/asreview
source pyenv/bin/activate
python -m asreview auth -u user1
```
Which will prompt to the entry of password.
To delete the user the following command is used
```sh
python -m asreview auth -u user1 -r
```
_Note that to update auth credentials on the running server, it needs to be restarted._

The passwords are stored in the file at standard path `~/.asreview/auth.txt`

## Accessing the ASReview
Once under UvA VPN or any other permitted network, the server can be accessed from any browser by navigating to `https://ivi-megameta.science.uva.nl` and entering the credentials, which should be sent to each intended user separately.

## Project files and backups
The ASReview project files are stored at default location `~/.asreview/`. 

There are two types of backups being made:
* Full system backup being done daily for the last 14 days. Rolling back to it will require asking responsible person from ICT Services and will affect all the progress (in all the projects!), which was made since the date of backup we are rolling back to.
* Per-project backups scheduled on `cron`
  * script run by cron is `~/backup.sh`
  * once a day at 21:00
    ```sh
    # Running
    crontab -e
    # Reads
    0 21 * * * /home/vmelnik/backup.sh
    ```
  * stored at `~/backup/incr/PROJECT_NAME/DATE_TIME`
  * made with `rsync` tool
  * incrementally, meaning that only files changed since the last backup are included in the new backup. This helps to save space. 
  * Just removing the older backups to save space is a valid approach due to rsync using links to files rather than hard copies. When removing older backup folders, the files are not deleted because they are referred to from the newer folders. So, something like below should work fine and delete all but the last 14 backups (but better to check on one project first):
    ```sh
      cd ~/backup/incr/PROJECT_NAME
      ls -v . | head -n -14 | xargs rm -r
    ```
  * Thus, if there is a server error, one can check if the disk space is enough and remove older backups with commands like the one given aboce.
  * An example of restoring the state of the project is given in `~/example_restore_cmd.txt`. As is done there, it is better to first restore the files to some third location, check their consistency and then only `cp -rf ...` to the project folder at `~/.asreview/`


# Funding

This project is funded by a grant from the Centre for Urban Mental Health, University of Amsterdam, The Netherlands.

# Contact
For any questions or remarks, please send an email to [Valentin Melnikov](https://orcid.org/0000-0002-9236-6717).

