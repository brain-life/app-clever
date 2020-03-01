set -e

docker pull r-base:3.6.2

docker build --no-cache -t damondpham/clever . 
docker tag damondpham/clever damondpham/clever:1.4
docker push damondpham/clever:1.4

