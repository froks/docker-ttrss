#!/bin/sh

setup_ttrss()
{
    TTRSS_REPO_URL=https://git.tt-rss.org/git/tt-rss.git
    TTRSS_PATH=/var/www/ttrss

    TTRSS_PATH_THEMES=${TTRSS_PATH}/themes.local
    TTRSS_PATH_PLUGINS=${TTRSS_PATH}/plugins.local

    if [ ! -d ${TTRSS_PATH} ]; then
        mkdir -p ${TTRSS_PATH}
        echo "Setup: Setting up Tiny Tiny RSS (latest revision) ..."
        git clone --depth=1 ${TTRSS_REPO_URL} ${TTRSS_PATH}

        mkdir -p ${TTRSS_PATH_PLUGINS}
        git clone --depth=1 https://github.com/sepich/tt-rss-mobilize.git ${TTRSS_PATH_PLUGINS}/mobilize
        git clone --depth=1 https://github.com/feediron/ttrss_plugin-feediron.git ${TTRSS_PATH_PLUGINS}/feediron
        git clone --depth=1 https://github.com/DigitalDJ/tinytinyrss-fever-plugin.git ${TTRSS_PATH_PLUGINS}/fever

        mkdir -p ${TTRSS_PATH_THEMES}
        git clone --depth=1 https://github.com/levito/tt-rss-feedly-theme.git ${TTRSS_PATH_THEMES}/levito-feedly-git
        git clone --depth=1 https://github.com/Gravemind/tt-rss-feedlish-theme.git ${TTRSS_PATH_THEMES}/gravemind-feedly-git
    fi

    # Add initial config.
    cp ${TTRSS_PATH}/config.php-dist ${TTRSS_PATH}/config.php

    # Check if TTRSS_URL is undefined, and if so, use localhost as default.
    if [ -z ${TTRSS_URL} ]; then
        TTRSS_URL=localhost
    fi

    # If no protocol is specified, use http as default. Not secure, I know.
    if [ -z ${TTRSS_PROTO} ]; then
        TTRSS_PROTO=http
    fi

    # Add a leading colon (for the final URL) to the port.
    if [ -n "$TTRSS_PORT" ]; then
        TTRSS_PORT=:${TTRSS_PORT}
    fi

    # If we've been passed $TTRSS_SELF_URL as an env variable, then use that,
    # otherwise use the URL we constructed above.
    if [ -z "$TTRSS_SELF_URL" ]; then
  	    # Construct the final URL TTRSS will use.
   	    TTRSS_SELF_URL=${TTRSS_PROTO}://${TTRSS_URL}${TTRSS_PORT}/
    fi

    echo "Setup: URL is: $TTRSS_SELF_URL"

    # By default we want to reset the theme to the default one.
    if [ -z ${TTRSS_THEME_RESET} ]; then
        TTRSS_THEME_RESET=1
    fi

    # Patch URL path.
    sed -i -e "s@define('SELF_URL_PATH'.*@define('SELF_URL_PATH', '$TTRSS_SELF_URL');@g" ${TTRSS_PATH}/config.php

    # Check if single user mode is selected
    if [ "$TTRSS_SINGLEUSER" = true ]; then
        echo "Single User mode Selected"
        sed -i -e "s/.*define('SINGLE_USER_MODE'.*/define('SINGLE_USER_MODE', 'true');/g" ${TTRSS_PATH}/config.php
    fi

    # Enable additional system plugins.
    if [ -z ${TTRSS_PLUGINS} ]; then

        TTRSS_PLUGINS=

        # Only if SSL/TLS is enabled: af_zz_imgproxy (Loads insecure images via built-in proxy).
        if [ "$TTRSS_PROTO" = "https" ]; then
            TTRSS_PLUGINS=${TTRSS_PLUGINS}af_zz_imgproxy
        fi
    fi

    echo "Setup: Additional plugins: $TTRSS_PLUGINS"

    sed -i -e "s/.*define('PLUGINS'.*/define('PLUGINS', '$TTRSS_PLUGINS, auth_internal, note, updater');/g" ${TTRSS_PATH}/config.php

    # Export variables for sub shells.
    export TTRSS_PATH
    export TTRSS_PATH_PLUGINS
    export TTRSS_THEME_RESET
}

setup_db()
{
    echo "Setup: Database"
    php -f /srv/ttrss-configure-db.php
    php -f /srv/ttrss-configure-plugin-mobilize.php
}

setup_ttrss
setup_db

echo "Setup: Applying updates ..."
/srv/update-ttrss.sh --no-start

echo "Setup: Done"
