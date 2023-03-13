<?php
/*
 Добавление связи между клиентом и картой
Параметры
$clientid - обязательный не 0
$cardnum - обязательный не 0
Результат: 1 - если успешно и 0 при неудаче
 */
require_once("Controller.php");

extract($_POST,EXTR_PREFIX_ALL,'f');
if (!isset($f_clientid) || !isset($f_cardnum) || ($f_clientid<1) || ($f_cardnum<1)) {
    echo json_encode(0);
    exit();
}
// Ищем карту в БД
$result=$db->query('select count(*) from cards where (number=?s)',$f_cardnum);
$cnt = (int)$result->fetch_assoc_array()[0];
if ($cnt==0) {
    // Если в БД нет карты, то добавляем ее
    $result=$db->query('insert into cards (number) values (?s)',$f_cardnum);
    if (!$result) {
        echo json_encode(0);
        exit();
    }
}
$result=$db->query('insert into clients_cards (clients_id, Cards_number) '.
    ' values (?i,?i)', $f_clientid, $f_cardnum);
if ($result==true) {
    echo json_encode(1);
}
?>