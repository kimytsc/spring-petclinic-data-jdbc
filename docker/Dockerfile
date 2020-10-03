FROM openjdk:8-jdk-alpine

ARG TZ=UTC
RUN apk add --no-cache tzdata \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone

RUN addgroup --gid 1000 uid \
    # Failed to auto-negotiate a Wavefront api token from https://wavefront.surf. The error was:
    # java.io.FileNotFoundException: /home/uid/.wavefront_freemium (No such file or directory)
    && adduser -G uid -u 1000 -D uid
    # && adduser -G uid -u 1000 -D -H uid \
    # && mkdir /tmp/home \
    # && ln -snf /tmp/home /home/uid

# USER uid

ARG JAR_FILE
COPY --chown=1000:1000 ${JAR_FILE} app.jar

ENTRYPOINT [ "java", "-jar", "/app.jar" ]
