#!/bin/sh

TTRSS_PATH=/var/www/ttrss
TTRSS_PATH_THEMES=${TTRSS_PATH}/themes.local
TTRSS_PATH_PLUGINS=${TTRSS_PATH}/plugins.local

update_ttrss()
{
    echo "Updating: Tiny Tiny RSS"
    ( cd ${TTRSS_PATH} && git pull origin HEAD )
}

update_plugin_mobilize()
{
    echo "Updating: Mobilize plugin"
    ( cd ${TTRSS_PATH_PLUGINS}/mobilize && git pull origin HEAD )

    # Patch ttrss-mobilize plugin for getting it to work.
    sed -i -e "s/<?$/<?php/g" ${TTRSS_PATH_PLUGINS}/mobilize/m.php
}

update_plugin_feediron()
{
    echo "Updating: FeedIron"
    ( cd ${TTRSS_PATH_PLUGINS}/feediron && git pull origin HEAD )
}

update_plugin_fever()
{
    echo "Updating: Fever"
    ( cd ${TTRSS_PATH_PLUGINS}/fever && git pull origin HEAD )
}

update_themes()
{
    echo "Updating: Themes"

    ( cd ${TTRSS_PATH_THEMES}/levito-feedly-git && git pull origin HEAD )
    ( cd ${TTRSS_PATH_THEMES}/gravemind-feedly-git && git pull origin HEAD )

    cd ${TTRSS_PATH_THEMES}

    # Link Levito theme to TTRSS.
    ln -f -s ${TTRSS_PATH_THEMES}/levito-feedly-git/feedly
    ln -f -s ${TTRSS_PATH_THEMES}/levito-feedly-git/feedly.css

    # Link Gravemind theme to TTRSS.
    ln -f -s ${TTRSS_PATH_THEMES}/gravemind-feedly-git/feedlish.css
    ln -f -s ${TTRSS_PATH_THEMES}/gravemind-feedly-git/feedlish.css.map
    ln -f -s ${TTRSS_PATH_THEMES}/gravemind-feedly-git/feedlish-night.css
    ln -f -s ${TTRSS_PATH_THEMES}/gravemind-feedly-git/feedlish-night.css.map
}

update_common()
{
    # When called initially by setup, it should set the common permissions once, later - when called as www-data,
    # setting them would fail
    CURRENT_UID=$(id -u -n)
    if [ "$CURRENT_UID" != "root" ]; then
      return
    fi

    echo "Updating: Updating permissions"
    for CUR_DIR in /etc/nginx /etc/php7 /var/lib/nginx /etc/services.d; do
        chown -R root:root ${CUR_DIR}
    done

    chown -R www-data:www-data ${TTRSS_PATH}

    echo "Updating: Updating permissions done"
}

update_ttrss
update_plugin_mobilize
update_plugin_feediron
update_plugin_fever
update_themes
update_common

echo "Update: Done"

if [ "$1" != "--no-start" ]; then
    echo "Update: Starting all ..."
fi

if [ "$1" = "--wait-exit" ]; then
    UPDATE_WAIT_TIME=$2
    if [ -z "$UPDATE_WAIT_TIME" ]; then
        UPDATE_WAIT_TIME=24h # Default is to check every day (24 hours).
    fi
    echo "Update: Sleeping for $UPDATE_WAIT_TIME ..."
    sleep ${UPDATE_WAIT_TIME}
fi
