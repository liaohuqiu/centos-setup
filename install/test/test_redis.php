<?php
$redis = new Redis();
$redis->connect('127.0.0.1', 6379);
$redis->set('test_key', 1);
var_dump($redis->get('test_key'));
echo $redis->get('test_key') == 1 ? "OK\n" : "Bad\n";
