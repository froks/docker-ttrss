#!/usr/bin/env php
<?php

include '/srv/ttrss-utils.php';

$eport = 5432;

$db_type = env('DB_TYPE','pgsql');
if ($db_type == 'mysql'){
    $eport = 3306;
}
$confpath = '/var/www/ttrss/config.php';

$config = array();
$config['DB_TYPE'] = $db_type;
$config['DB_HOST'] = env('DB_HOST', 'db');
$config['DB_PORT'] = env('DB_PORT', $eport);

// database credentials for this instance
//   database name (DB_NAME) can be supplied or detaults to "ttrss"
//   database user (DB_USER) can be supplied or defaults to database name
//   database pass (DB_PASS) can be supplied or defaults to database user
$config['DB_NAME'] = env('DB_NAME', 'ttrss');
$config['DB_USER'] = env('DB_USER', $config['DB_NAME']);
$config['DB_PASS'] = env('DB_PASS', $config['DB_USER']);

$pdo = dbconnect($config);
try {
    $pdo->query('SELECT 1 FROM plugin_mobilize_feeds');
    // reached this point => table found, assume db is complete
}
catch (PDOException $e) {
    echo 'Database table for mobilize plugin not found, applying schema... ' . PHP_EOL;
    $schema = file_get_contents('/srv/ttrss-plugin-mobilize.'.$db_type);
    $schema = preg_replace('/--(.*?);/', '', $schema);
    $schema = preg_replace('/[\r\n]/', ' ', $schema);
    $schema = trim($schema, ' ;');
    foreach (explode(';', $schema) as $stm) {
        $pdo->exec($stm);
    }
    unset($pdo);
}

$contents = file_get_contents($confpath);
foreach ($config as $name => $value) {
    $contents = preg_replace('/(define\s*\(\'' . $name . '\',\s*)(.*)(\);)/', '$1"' . $value . '"$3', $contents);
}
file_put_contents($confpath, $contents);
