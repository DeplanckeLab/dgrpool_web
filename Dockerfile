# Use the Docker image format
# syntax=docker/dockerfile:1

FROM ruby:3.1.2-alpine

RUN apk add postgresql-dev git build-base nodejs bash npm yarn busybox-extras curl wget openjdk11-jre less gzip

#RUN Rscript -e "install.packages(c('data.table'), repos='http://stat.ethz.ch/CRAN/');"

RUN mkdir -p /opt/mimemagic
WORKDIR /opt/dgrpool
ENV FREEDESKTOP_MIME_TYPES_PATH=/opt/mimemagic
COPY src/Gemfile .
RUN bundle install
COPY src/. .
CMD ["rm ./tmp/pids/server.pid"]

# Add health check script
COPY healthcheck.sh ./

# Set execute permissions
RUN chmod +x /opt/dgrpool/healthcheck.sh

# Define health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 CMD /opt/dgrpool/healthcheck.sh || exit 1

# Start solr server, esbuild and scss builders and puma server
CMD ["sh", "start.sh"]
