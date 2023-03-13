<?php
/*
 * Получение списка клиентов, связанных с картой.
 * Если карта отсутствует в таблице карт, то добавляем ее туда
 * Параметры:
 * $cardnum: - обязательный
 * Результат: массив клиентов, связанных с картой
 */
require_once("Controller.php");

if (!isset($_GET['cardnum'])) {
    header('HTTP/1.0 500 Internal Server Error');
    exit();
} else {$cardnum=$_GET['cardnum'];}
// Ищем карту в БД
$result=$db->query('select count(*) as cnt from cards where (number=?s)',$cardnum);
$res = $result->fetch_assoc_array();
$cnt = (int)$res[0]['cnt'];
if ($cnt==0) {
    // Если в БД нет карты, то добавляем ее
    $result=$db->query('insert into cards (number) values (?s)',$cardnum);
    if (!$result) {
        header('HTTP/1.0 500 Internal Server Error');
        exit();
    }
}
// Ищем клиентов по карте в БД
$result=$db->query('select c.id, '.
    'c.surname, '.
    'c.name, '.
    'c.second_name, '.
    'DATE_FORMAT( c.birthday , "%d.%m.%Y")  AS birthday, '.
    'c.address, '.
    'c.phone, '.
    'c.email, '.
    'c.photo, '.
    'c.sign '.
    'from clients_cards cc inner join clients c on (c.id=cc.clients_id) '.
    'where (cc.Cards_number=?s) order by surname,name,second_name',$cardnum);
$clientsList=$result->fetch_assoc_array();
echo(json_encode($clientsList));
?>