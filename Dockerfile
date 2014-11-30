FROM centos:centos6
ADD install /install
RUN /install/install.sh
