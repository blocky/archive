FROM alpine:3.20.0

RUN apk add --no-cache bash=5.2.26-r0 tar=1.35-r2
COPY ./archive.sh /

ENTRYPOINT ["bash",  "archive.sh"]
