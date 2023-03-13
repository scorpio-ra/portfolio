<?php
require_once('libs/Statement.php');
require_once('libs/Mysql.php');
$db = Mysql::create("127.0.0.1", "terminal", "***")
      // Выбор базы данных
      ->setDatabaseName("cli_info")
      // Выбор кодировки
      ->setCharset("utf8");
?>