<?php

function env($name, $default = null)
{
    $v = getenv($name) ?: $default;

    if ($v === null) {
        error('The env ' . $name . ' does not exist');
    }

    return $v;
}

function error($text)
{
    echo 'Error: ' . $text . PHP_EOL;
    exit(1);
}

function dbconnect()
{
    $map = array('host' => 'HOST', 'port' => 'PORT', 'dbname' => 'NAME', 'user' => 'USER', 'password' => 'PASS');
    $dsn = env('TTRSS_DB_TYPE') . ':';
    foreach ($map as $d => $h) {
        if (isset($config['DB_' . $h])) {
            $dsn .= $d . '=' . env('TTRSS_DB_' . $h) . ';';
        }
    }
    echo($dsn);
    if (env('TTRSS_DB_TYPE', 'pgsql') == 'pgsql'){
        $pdo = new \PDO($dsn);
    } else {
        $pdo = new \PDO($dsn, env('TTRSS_DB_USER'), env('TTRSS_DB_PASS'));
    }
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    return $pdo;
}

function dbcheck()
{
    try {
        dbconnect();
        return true;
    }
    catch (PDOException $e) {
        return false;
    }
}

?>
