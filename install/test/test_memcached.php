<?php
$memcached = new Memcached();
$memcached->addServer('127.0.0.1', 11211);
$memcached->set('test', false);
var_dump($memcached->get('test'));
var_dump($memcached->get('1test'));
