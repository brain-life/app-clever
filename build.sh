set -e

docker pull r-base:3.6.2

docker build --no-cache -t mandymejia/clever . 
docker tag mandymejia/clever mandymejia/clever:1.5
docker push mandymejia/clever:1.5
