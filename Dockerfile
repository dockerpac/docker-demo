FROM node:16 as ui
WORKDIR /usr/src/app
COPY . /usr/src/app
WORKDIR /usr/src/app/ui
RUN npm install
WORKDIR /usr/src/app
RUN mkdir -p ui/semantic/src/themes/app && \
    cp -f ui/semantic.theme.config ui/semantic/src/theme.config && \
    cp -rf ui/semantic.theme/* ui/semantic/src/themes/app
WORKDIR /usr/src/app/ui/semantic
RUN npx gulp build

FROM golang:1.19-alpine as app
RUN apk add -U build-base git
COPY . /go/src/app
WORKDIR /go/src/app
ENV GO111MODULE=on
RUN go build -a -v -tags 'netgo' -ldflags '-w -linkmode external -extldflags -static' -o docker-demo .

FROM alpine:3.6
RUN apk add -U --no-cache curl
RUN adduser -D myuser
COPY --chown=myuser:myuser static /home/myuser/static
COPY --from=ui --chown=myuser:myuser /usr/src/app/ui/semantic/dist/semantic.min.css /home/myuser/static/dist/semantic.min.css
COPY --from=ui --chown=myuser:myuser /usr/src/app/ui/semantic/dist/semantic.min.js /home/myuser/static/dist/semantic.min.js
COPY --from=ui --chown=myuser:myuser /usr/src/app/ui/semantic/dist/themes/default/assets /home/myuser/static/dist/themes/default/
COPY --from=app --chown=myuser:myuser /go/src/app/docker-demo home/myuser/docker-demo
COPY --chown=myuser:myuser templates /home/myuser/templates
USER myuser
WORKDIR /home/myuser
EXPOSE 8080
ENTRYPOINT ["/home/myuser/docker-demo"]
