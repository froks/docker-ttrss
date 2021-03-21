#!/usr/bin/env php
<?php

include '/srv/ttrss-utils.php';

$confpath = '/var/www/ttrss/';

if (!dbcheck()) {
    echo 'Database login failed, trying to create ...' . PHP_EOL;
    // superuser account to create new database and corresponding user account
    //   username (SU_USER) can be supplied or defaults to "docker"
    //   password (SU_PASS) can be supplied or defaults to username

    $super['DB_NAME'] = null;
    $super['DB_USER'] = env('DB_ENV_USER', 'docker');
    $super['DB_PASS'] = env('DB_ENV_PASS', $super['DB_USER']);

    $pdo = dbconnect($super);
    if(env('TTRSS_DB_TYPE', 'pgsql') == 'mysql') {
        $pdo->exec('CREATE USER \'' . (env('TTRSS_DB_USER')) . '\' IDENTIFIED BY \'' . env('TTRSS_DB_PASS') . '\'');
        $pdo->exec('CREATE DATABASE ' . (env('TTRSS_DB_NAME')));
        $pdo->exec('GRANT ALL PRIVILEGES ON ' . (env('TTRSS_DB_NAME')) . '.* TO \'' . (env('TTRSS_DB_USER')) . '\'');
    } else {
        $pdo->exec('CREATE ROLE ' . (env('TTRSS_DB_USER')) . ' WITH LOGIN PASSWORD ' . $pdo->quote(env('DB_PASS')));
        $pdo->exec('CREATE DATABASE ' . (env('TTRSS_DB_NAME')) . ' WITH OWNER ' . (env('TTRSS_DB_USER')));
    }
    unset($pdo);

    if (dbcheck()) {
        echo 'Database login created and confirmed' . PHP_EOL;
    } else {
        error('Database login failed, trying to create login failed as well');
    }
}

$pdo = dbconnect();
try {
    $pdo->query('SELECT 1 FROM ttrss_feeds');
    echo 'Connection to database successful' . PHP_EOL;
    // Reached this point => table found, assume db is complete

    if (env('TTRSS_THEME_RESET', '1')) {
        // Make sure to set the default theme provided by TT-RSS.
        // Other themes might break everything after an update, so play safe here.
        echo 'Resetting theme to default ...' . PHP_EOL;
        $pdo->query("UPDATE ttrss_user_prefs SET value = '' WHERE pref_name = 'USER_CSS_THEME'");
    }
}
catch (PDOException $e) {
    echo 'Database table not found, applying schema... ' . PHP_EOL;
    $schema = file_get_contents($confpath . 'schema/ttrss_schema_' . $config['DB_TYPE'] . '.sql');
    $schema = preg_replace('/--(.*?);/', '', $schema);
    $schema = preg_replace('/[\r\n]/', ' ', $schema);
    $schema = trim($schema, ' ;');
    foreach (explode(';', $schema) as $stm) {
        $pdo->exec($stm);
    }
    unset($pdo);
}
