<?php
$memcached = new Memcached();
$memcached->addServer('127.0.0.1', 11211);
$memcached->set('test', 1);
var_dump($memcached->get('test'));
