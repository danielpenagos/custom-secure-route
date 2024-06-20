FROM quay.io/redhattraining/hello-world-nginx
COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 8443
