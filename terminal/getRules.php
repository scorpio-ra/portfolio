<?php
/* Получение правил нахождения в парке на текущее время
 */
require_once("Controller.php");
$dt=date('Y-m-d H:i:s');
$result=$db->query("select id, rules, start_date from rules_history where start_date<'".$dt."' order by start_date DESC");
$request = $result->fetch_assoc_array();
$rules=$request[0];
echo json_encode($rules);
?>