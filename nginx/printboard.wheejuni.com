server {
    listen 80;
    listen[::]:80;

    server_name printapi.wheejuni.com;
    client_max_body_size 20M;

    include /etc/nginx/conf.d/print-service-url.inc;

    location / {
        proxy_pass $service_url;
        proxy_set_header X-Real_IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $http_host
    }

}