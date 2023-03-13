<?php
/*
 * Получение списка детей, связанных с картой.
 * Если карта отсутствует в таблице карт, то добавляем ее туда
 * Параметры:
 * $cardnum: - обязательный
 * Результат: массив детей, связанных с картой
 */

require_once("Controller.php");
if (!isset($_GET['cardnum'])) {
    header('HTTP/1.0 500 Internal Server Error');
    exit();
} else {$cardnum=$_GET['cardnum'];}
$result=$db->query('select ch.id, ch.fio, DATE_FORMAT( ch.birthday , "%d.%m.%Y")  AS birthday from childrens ch '.
    'inner join clientchildrens clch on (clch.childrens_id=ch.id) '.
    'inner join clients_cards cc on (clch.clients_id=cc.clients_id) where cc.Cards_number=?s',$cardnum);
$childrensList=$result->fetch_assoc_array();
echo(json_encode($childrensList));
?>
