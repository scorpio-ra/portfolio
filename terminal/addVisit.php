<?php
/*
 Добавление визита в БД
Параметры
$clientId - обязательный. Id клиента
$cardNumber - обязательный. Номер карты. Если 0, то без карты
$rulesId - обязательный. ID правил
$childrens - массив идентификаторов детей
Результат: 1 при успешном добавлении или 0, если не удалось сохранить данные
 */
require_once("Controller.php");

extract($_POST,EXTR_PREFIX_ALL,'f');
if (!isset($f_clientId) || !isset($f_cardNumber) || !isset($f_rulesId) || ($f_clientId<1) || ($f_rulesId<1)) {
    echo json_encode(0);
    exit();
}
if (!isset($f_childrens) || !is_array($f_childrens)) {
    $f_childrens = array();
}
if ($f_cardNumber=="0") {
    $card_plh='?n';
} else {
    $card_plh='"?s"';
}
$result=$db->query('insert into visit (Clients_id, Cards_number, rules_history_id, visit_time) '.
    ' values (?i,'.$card_plh.',?i,"'.date('Y-m-d H:i:s').'")', $f_clientId, $f_cardNumber,$f_rulesId);
if ($result==true) {
    $visit_id=$db->getLastInsertId();
} else {echo json_encode(0); exit();}
// Если визит был создан, то привязываем к нему детей
if ($visit_id>0) {
    if (count($f_childrens)>0) {
        $qry = $db->prepare('insert into visit_childrens (visit_id, childrens_id) values ');
        foreach ($f_childrens as $child_id) {
            $qry .= $db->prepare('(?i,?i),', $visit_id, $child_id);
        }
        $qry = substr($qry, 0, -1);
        $result = $db->query($qry);
        if ($result == true) {
            echo json_encode(1);
        } else {
            echo json_encode(0);
        }
    } else { echo json_encode(1); }
}

?>