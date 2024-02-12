FROM ruby:3.1.1-alpine

RUN apk add libsqlite3-dev git build-base nodejs bash npm yarn busybox-extras curl gcompat

RUN mkdir -p /opt/mimemagic

WORKDIR /opt/dgrpool/src

COPY ./src .

ENV FREEDESKTOP_MIME_TYPES_PATH=/opt/mimemagic RAILS_ENV=production

CMD ["./start.sh"]