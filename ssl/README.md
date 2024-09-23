# SSL Certificate with Certbot

This setup is based on the already existing [docker-compose.yml](../docker-compose.yml).


## Setup

- Copy `docker-compose.yml`
- Copy `.env.example` and rename it to `.env`
- Fill in your information in the new `.env` file
- If you want to change the default config for the server itself, see [Environment Variables](../README.md#environment-variables)
- Make sure you open the port `80/tcp` additionally

It should now be ready for deployment. Start the process with `docker-compose up -d`.

Certbot will run before the server starts. If it fails, the server itself will **NOT** start.

## Troubleshooting

### I have a reverse proxy, port 80 is already blocked

This shouldn't be a problem. Just change the port for the certbot service (like `7780:80`) and forward HTTP traffic to certbot.

Here are some examples for some proxies:

#### NGINX

Should be straightforward, as the simplest setup already uses HTTP instead of HTTPS.

```
server {
    listen       80;
    server_name  satisfactory.example.com;

    location / {
        proxy_pass  http://localhost:7780;
    }
}
```

#### Caddy

Put `http://` in front of your domain like this:

`/etc/caddy/Caddyfile`
```caddyfile
http://example.com {
    reverse_proxy :7780
}
