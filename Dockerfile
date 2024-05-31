FROM alpine

RUN apk add bash
RUN apk add tar=1.34-r1
COPY ./archive.sh /
RUN mkdir /data

ENTRYPOINT ["bash",  "archive.sh"]
