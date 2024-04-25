FROM ruby:3.1.2-alpine
<<<<<<< HEAD
RUN apk add postgresql-dev git build-base nodejs bash npm yarn busybox-extras curl wget openjdk11-jre less gzip
=======
RUN apk add postgresql-dev git build-base nodejs bash npm yarn busybox-extras curl wget openjdk8-jre less gzip
#R \
#R-dev \
#    curl-dev \
#    libxml2-dev \
#    openssl-dev \
#    udns-dev \
#    gdal-dev \
#    geos-dev \
#    proj-dev
>>>>>>> 7b30093041593bdc970e6bd36c8165fa5955b978

#RUN Rscript -e "install.packages(c('data.table'), repos='http://stat.ethz.ch/CRAN/');"

RUN mkdir -p /opt/mimemagic
WORKDIR /opt/dgrpool
ENV FREEDESKTOP_MIME_TYPES_PATH=/opt/mimemagic
COPY src/Gemfile .
RUN bundle install
COPY src/. .
CMD ["rm ./tmp/pids/server.pid"]
CMD ["sh", "start.sh"]
