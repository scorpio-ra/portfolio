<?php
/*
 Добавление связи между клиентом и ребенком
Параметры
$clientid - обязательный не 0
$childid - обязательный не 0
Результат: 1 - если успешно и 0 при неудаче
 */
require_once("Controller.php");

extract($_POST,EXTR_PREFIX_ALL,'f');
if (!isset($f_clientid) || !isset($f_childid) || ($f_clientid<1) || ($f_childid<1)) {
    echo json_encode(0);
    exit();
}
$result=$db->query('insert into clientchildrens (clients_id, childrens_id) '.
    ' values (?i,?i)', $f_clientid, $f_childid);
if ($result==true) {
    //$arr=array('res'=>1);
    echo json_encode(1);
}

?>
