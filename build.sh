docker pull r-base:3.5.0
docker build -t brainlife/clever . && \
	docker tag brainlife/clever brainlife/clever:1.0 && \
	docker push brainlife/clever

