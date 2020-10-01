set -e

docker pull r-base:4.0.2

docker build -t damondpham/clever . 
docker tag damondpham/clever damondpham/clever:2.0
docker push damondpham/clever

