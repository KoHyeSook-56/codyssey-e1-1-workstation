FROM nginx:alpine

LABEL org.opencontainers.image.title="codyssey-workstation-web"
LABEL org.opencontainers.image.description="E1_1 Dockerfile practice web server"

ENV APP_ENV=practice

COPY site/ /usr/share/nginx/html/

EXPOSE 80
