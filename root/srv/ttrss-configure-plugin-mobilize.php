#!/usr/bin/env php
<?php

include '/srv/ttrss-utils.php';

$eport = 5432;

$db_type = env('TTRSS_DB_TYPE','pgsql');
if ($db_type == 'mysql'){
    $eport = 3306;
}
$confpath = '/var/www/ttrss/config.php';

$pdo = dbconnect();
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
