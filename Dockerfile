FROM centos:centos6
ADD image /image
RUN /image/install.sh
