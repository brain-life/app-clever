FROM r-base:4.0.2

MAINTAINER Soichi Hayashi <hayashis@iu.edu>

RUN apt update && apt install -y r-cran-devtools libssl-dev

RUN R -e "devtools::install_github('mandymejia/clever')" #2.0

RUN R -e "install.packages('oro.nifti')"
RUN R -e "install.packages('rjson')"
RUN R -e "install.packages('ggplot2')"

#to test 
#R -e 'library("clever"); help("clever")'

RUN apt install -y jq

#make it work under singularity
RUN ldconfig && mkdir -p /N/u /N/home /N/dc2 /N/soft
