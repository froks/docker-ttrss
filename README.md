﻿Based on the works of https://github.com/x86dev/docker-ttrss

Additional features:
- install & auto-updates the fever plugin (https://github.com/DigitalDJ/tinytinyrss-fever-plugin)

Changes:
- Database configuration allows host-parameter `DB_HOST` and `DB_PORT`, as the DB_PORT... syntax isn't used since docker-compose v2+ anymore.
- Removed configuration of specific paths for content, and specific git-tags for checkout, as well as repository urls to simplify maintenance and improve readability
- Removed ssl configuration - the intention is to have a tls-terminating nginx before

Fixes:
- Database creation with mariadb
- Update-cycle was twice as long as intended, now 24h
- Updates now don't throw errors dues to missing permissions (runs as www-data, but tried to update system folder permissions) 
- Separate folder (/shared/feed-icons), so they can be persisted through external volumes

`# docker login docker.pkg.github.com <your token>`

Example docker-compose.yml for mariadb:

```
version: '3.1'

services:
  ttrss-db:
    image: mariadb:10.5
    container_name: ttrss-db
    restart: unless-stopped
    volumes:
      - "/persistent/database:/var/lib/mysql"
    environment:
      - MYSQL_ROOT_PASSWORD
    networks:
      - ttrss-net
  ttrss:
    image: docker.pkg.github.com/froks/docker-ttrss/ttrss:0.7
    container_name: ttrss
    restart: unless-stopped
    volumes:
      - "feed-icons:/shared/feed-icons"
    environment:
      - TTRSS_URL=localhost
      - TTRSS_PORT=8080
      - DB_TYPE=mysql
      - DB_HOST=ttrss-db
      - DB_PORT=3306
      - DB_ENV_USER
      - DB_ENV_PASS
      - TTRSS_SELF_URL
      - TTRSS_PROTO
      - DB_NAME
      - DB_USER
      - DB_PASS
    links:
      - "ttrss-db:ttrss-db"
    ports:
      - "127.0.0.1:8080:8080"
    networks:
      - ttrss-net

networks:
  ttrss-net:

volumes:
  feed-icons:
```

# docker-ttrss

This Dockerfile installs Tiny Tiny RSS (TT-RSS) with the following features:

- **New:** Now uses a dedicated volume for the Postgres database data
- **New:** Integrated [Feedly-ish theme](https://github.com/Gravemind/tt-rss-feedlish-theme) for supporting latest TT-RSS versions
- **New:** When starting the container, the default theme will be (re-)applied. This should help when a theme breaks (again)
- Based on [Docker-Alpine](https://github.com/gliderlabs/docker-alpine) and [s6](http://skarnet.org/software/s6/) as the supervisor
- Using PHP 7
- Small and lightweight image size (< 100 MB)
- Rolling release support: Updates TT-RSS automatically every day
- Works nicely with jwilder's [nginx-proxy](https://github.com/jwilder/nginx-proxy), e.g. to use for Let's Encrypt SSL certificates
- Integrated [Feedly theme](https://github.com/levito/tt-rss-feedly-theme)
- Integrated [FeedIron plugin](https://github.com/m42e/ttrss_plugin-feediron) to get modify feeds
- Integrated [Mobilize plugin](https://github.com/sepich/tt-rss-mobilize) for using Readability, Instapaper + Google Mobilizer
- Optional: Self-signed 4096-bit RSA TLS certificate for accessing TT-RSS via https
- Originally was based on [clue/docker-ttrss](https://github.com/clue/docker-ttrss)

A ready-to-use Docker image is available at [Docker Hub](https://hub.docker.com/r/x86dev/docker-ttrss/)

Feel free to tweak this further to your likings.

This docker image allows you to run the [Tiny Tiny RSS](http://www.tt-rss.org) feed reader.
Keep your feed history to yourself and access your RSS and atom feeds from everywhere.
You can access it through an easy to use webinterface on your desktop, your mobile browser
or using one of available apps.

**Note: All commands must be executed as root!**

## Quickstart

This section assumes you want to get started quickly, the following sections explain the
steps in more detail. So let's start.

Create a new database volume:

```bash
# docker volume create ttrss-db
```

Create a Postgres database instance:

```bash
# DB=$(docker run -d --restart=always --name ttrss-db -v ttrss-db:/var/lib/postgresql/data -e POSTGRES_PASSWORD=password postgres:alpine)
```

Next, run the actual TT-RSS instance by doing a:

```bash
# docker run -d --link $DB:db -e TTRSS_PORT=8080 --name ttrss x86dev/docker-ttrss
```

Running this command for the first time will download the image automatically.


## Accessing your Tiny Tiny RSS (TT-RSS)

The above example exposes the TT-RSS web interface on port 8080 (http / unencrypted), so that you can browse to:

```bash
http://localhost:8080
```

The default login credentials are:

```bash
Username: admin
Password: password
```

Obviously, you're recommended to change those ASAP.
See the next section about how to enable encryption support (via SSL/TLS).


## Use self-signed certificates (SSL/TLS)

For enabling SSL/TLS support with a self-signed certificate you have to add `-e TTRSS_WITH_SELFSIGNED_CERT=1 -p 443:4443`
when running your TT-RSS container. Then you can access TT-RSS via: `https://<yourhost>`.

**Warning: Running services unencrypted on the Internet is not recommended!**

The container also has been successfully tested with Let's Encrypt certificates.


## Reverse proxy support

A nice thing to have is jwilder's [nginx-proxy](https://github.com/jwilder/nginx-proxy) as a separate
Docker container running on the same machine as this one.

That way you easily can integrate your TT-RSS instance with an existing domain by using a sub domain
(e.g. https://ttrss.yourdomain.tld).

### Enabling SSL/TLS encryption support

In combination with an official Let's Encrypt certificate you
can get a nice A+ encryption/security rating over at [SSLLabs](https://www.ssllabs.com/ssltest/).


## Installation walkthrough

### Running

Following Docker's best practices, this container does not contain its own database,
but instead expects you to supply a running database instance.
While slightly more complicated at first, this gives your more freedom as to which
database instance and configuration you're relying on.
Also, this makes this container quite disposable, as it doesn't store any sensitive
information at all.


### Starting a database instance

This container requires a PostgreSQL database instance. You're free to pick (or build)
any, as long as is exposes its database port (5432) to the outside.

Example:

```bash
# docker volume create ttrss-db
# docker run -d --restart=always --name=ttrss-db -v ttrss-db:/var/lib/postgresql/data -e POSTGRES_PASSWORD=<password> postgres:alpine
```

Note: The above example creates a separate data volume where the actual Postgres database data lives in.

### Testing TT-RSS in foreground

For testing purposes it's recommended to initially start this container in foreground.
This is particular useful for your initial database setup, as errors get reported to
the console and further execution will halt.

```bash
# docker run -it -e TTRSS_PORT=8080 --link ttrss-db:db --name ttrss x86dev/docker-ttrss
```

### Database configuration

Whenever your run TT-RSS, it will check your database setup. It assumes the following
default configuration, which can be changed by passing the following additional arguments:

```bash
-e DB_NAME=ttrss
-e DB_USER=ttrss
-e DB_PASS=ttrss
```

By default, a PostgreSQL database is needed.

#### Use a MySQL database

Specify the following to use an existing MySQL database instead of a PostgreSQL one:
```bash
-e DB_TYPE=mysql
```

### Database user

When you run TT-RSS it will check your database setup. If it can not connect using the above
configuration, it will automatically try to create a new database and user.

For this to work, it will need a superuser (root) account that is permitted to create a new database
and user. It assumes the following default configuration, which can be changed by passing the
following additional arguments:

```bash
-e DB_ENV_USER=docker
-e DB_ENV_PASS=docker
```

### Running TT-RSS daemonized

Once you've confirmed everything works in the foreground, you can start your container
in the background by replacing the `-it` argument with `-d` (daemonize).
Remaining arguments can be passed just like before, the following is the recommended
minimum:

```bash
# docker run -d --link ttrss-db:db --name ttrss x86dev/docker-ttrss
```
## Useful stuff to know

### Single User mode
In case you are running behind a proxy that has basic auth and you do not wish to use
ttrss auth, you can set the enviroment variable TTRSS_SINGLEUSER to true and it
will change the setup to single user mode

### Backing up / moving to another server

Decided to back up your data container and/or move to another server? Here's how
you do it:

* On the old server, stop your TT-RSS container.
* Back up the database volume (```ttrss-db```) and copy it to the new server.
* Repeat the steps for creating the TT-RSS database container and the actual TT-RSS instance.
  This time the (old) database volume will be already around, so that you can start right away.

### Automatic updates

When running this docker container you don't need to worry anymore how and when to
update TT-RSS. Since TT-RSS has a so-called "rolling release" model since some time
(which essentially means that there won't be any specific versions like 1.0, 1.1 etc),
this container takes the burden any checks for updates of TT-RSS and the accompanied
plugins/themes every day via an own update script (see `root/srv/update-ttrss.sh`).

By default the update script checks every 24 hours if there are updates for TT-RSS,
the plugins or the theme(s) available.

If you want to change the update interval you just need to edit the file
`root/etc/services.d/ttrss-updater/run` and change the `--wait-exit 24h` to fit your needs, whereas
the suffix `h` stands for hours, `m` for minutes and `s` for seconds.


### Want to contribute?

You think you have something which absolutely must be part of this container, implemented
a cool new feature or fixed some nasty bug? Let me know and send me a git pull request.

The repository can be found [here](https://github.com/x86dev/docker-ttrss).
