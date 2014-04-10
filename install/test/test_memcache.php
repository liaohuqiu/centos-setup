<?php
$memcache = new Memcache;
$memcache->addServer('127.0.0.1', 11211);

$memcache->set('test', time());
echo $memcache->get('test');
