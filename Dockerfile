FROM alpine

RUN apk add --no-cache bash tar
COPY ./archive.sh /
RUN mkdir /data

ENTRYPOINT ["bash",  "archive.sh"]
