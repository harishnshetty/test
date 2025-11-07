FROM nginx:alpine

WORKDIR /usr/share/nginx/html
COPY index.html .
EXPOSE 80
ENTRYPOINT [ "nginx", "-g", "daemon off;"]