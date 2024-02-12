FROM ruby:3.2.2-alpine

RUN apk add postgresql-dev git build-base nodejs bash npm yarn busybox-extras curl gcompat


RUN apk add postgresql-dev git build-base nodejs bash npm yarn busybox-extras curl gcompat

RUN mkdir -p /opt/mimemagic

WORKDIR /opt/scfair/src

COPY ./src .

ENV FREEDESKTOP_MIME_TYPES_PATH=/opt/mimemagic

CMD ["./start.sh"]