
## GitHub Pull Request Crawler

This utility crawls pull requests from Github prepo and send a weekly digest to required email.

### Installing Prerequisites:
```
sudo apt-get install git curl vim -y
```
If using docker, then install docker by:
```
sudo apt-get -y install docker.io
```
or else if going native then install required packages as:
```
sudo apt-get -y install postfix git curl jq vim python3 python3-pip python3-setuptools
```

### Initial Setup:

```
git clone https://github.com/tech-alchemist/crawlghpr ~/.crawlghpr
cd ~/.crawlghpr
cp config.example.py config.py
vim ~/.crawlghpr/config.py      # Setup the required variables
```

### Dockerized Usage:

After initial setup as given above, build and use an image
```
docker build . -t ubuntu:sp
docker run -it ubuntu:sp
```


### Native Usage:

Install required packages:
```
sudo apt-get -y install postfix git curl jq vim python3 python3-pip python3-setuptools
```
```
/bin/bash ~/.crawlghpr/crawlghpr.sh <ORG/REPO> <RECEPIENT_EMAIL>
Example:
/bin/bash ~/.crawlghpr/crawlghpr.sh hashicorp/terraform abhis27@outlook.com
```

### Note:

> There are two versions: `crawlghpr.sh` for arguments based usage   
> and `crawlghpr_seamless.sh` for seamless usage.  

> For regular reports, both versions of utility may be used with the cron jobs.
