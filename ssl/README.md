# SSL Certificate with Certbot

The instructions below will help you to deploy a signed SSL certificate for your Satisfactory server.

## Docker Compose

```yaml
services:
  satisfactory-server:
    container_name: 'satisfactory-server'
    hostname: 'satisfactory-server'
    image: 'wolveix/satisfactory-server:latest'
    ports:
      - '7777:7777/tcp'
      - '7777:7777/udp'
      - '8888:8888/tcp'
    volumes:
      - './satisfactory-server:/config'
      - './certs/live/${DOMAIN}/fullchain.pem:/config/gamefiles/FactoryGame/Certificates/cert_chain.pem'
      - './certs/live/${DOMAIN}/privkey.pem:/config/gamefiles/FactoryGame/Certificates/private_key.pem'
    environment:
      - MAXPLAYERS=4
      - PGID=1000
      - PUID=1000
      - STEAMBETA=false
    restart: unless-stopped
    depends_on:
      certbot:
        condition: service_completed_successfully
    deploy:
      resources:
        limits:
          memory: 8G
        reservations:
          memory: 4G

  certbot:
    image: certbot/certbot
    command: certonly --standalone --non-interactive --agree-tos -m ${CERTBOT_MAIL} -d ${DOMAIN}
    ports:
      - '80:80/tcp'
    volumes:
      - ./certs:/etc/letsencrypt
    environment:
      - CERTBOT_MAIL=certbot@domain.tld
      - DOMAIN=satisfactory.domain.tld
```

The `docker-compose.yml` file above should replace the `docker-compose.yml` file you already have configured. Adjust the
`CERTBOT_MAIL` and `DOMAIN` environment variables under the `certbot` service to be a real email address, and the domain
you'd like to issue the SSL certificate for. Ensure prior to running this that you've already created the necessary DNS
record for your domain. If you don't certbot will fail, and you'll likely hit your rate limit and need to wait a while
to try again (check the `certbot` container's logs for further information).

**Ensure that you open/port forward for port `80/tcp`.**

You can now launch the Docker Compose configuration in the same way you normally would. Do note that if Certbot fails,
the game server will not start.

## Troubleshooting

### I can't reach the server with the new cert!

If you could reach the server before configuring a signed SSL cert, ensure that you're not doing either of the 
following:
- Using a wildcard cert: Satisfactory does not support them ([#354](https://github.com/wolveix/satisfactory-server/issues/354))
- Connecting to a hostname not specified in your cert: Satisfactory does not support this ([#354](https://github.com/wolveix/satisfactory-server/issues/354))
- Using your local IP. You cannot use your local IP, as it will not be included in your certificate.

### What if port 80 is already in-use with a reverse-proxy?

Change the port for the certbot service (e.g. `7800:80/tcp`), and forward HTTP traffic from your reverse proxy through
to your `certbot` container.

Here are examples on how you can do this with Caddy and NGINX

#### Caddy

Modify your Caddyfile to include your given domain above. Ensure that you put `http://` **before** the domain, otherwise
Caddy will _also_ request an SSL certificate for it.

```
http://satisfactory.domain.tld {
    reverse_proxy :7780
}
```


#### NGINX

Modify your NGINX configuration file to include the following virtual host:

```
server {
    listen       80;
    server_name  satisfactory.domain.tld;

    location / {
        proxy_pass  http://localhost:7780;
    }
}
```
