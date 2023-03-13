<?php
/* Сохранение данных о клиенте в базу данных
    Параметры
    $id - если не 0, то делаем Update, а если 0, то insert
    $surname - обязательный
    $name - обязательный
    $second_name
    $birthday - в формате дд.мм.гггг
    $phone - обязательный
    $address - обязательный
    $email
    $photo
    $sign
    $confirmed
Результат: ClientId. id клиента в таблице Clients или 0, если не удалось сохранить данные

*/
require_once("Controller.php");

extract($_POST,EXTR_PREFIX_ALL,'f');
if (!isset($f_id) || !isset($f_surname) || !isset($f_name) || !isset($f_phone) || !isset($f_address) ) {
    exit();
}
if (!isset($f_sign) || ($f_sign=="")) { $sign_plh='?n'; $f_sign=""; } else {$sign_plh='"?s"';}
if (!isset($f_second_name)) { $f_second_name="";}
if (!isset($f_birthday) || ($f_birthday=="")) { $f_birthday=""; $birth_plh='?n';} else {
    $birth_plh='"?s"';
    $f_birthday=date('Y-m-d',strtotime($f_birthday));
}
if (!isset($f_email)) { $f_email="";}
if (!isset($f_photo)) { $f_photo="";}
if (!isset($f_confirmed)) {$f_confirmed=0;}

// Если id 0, то делаем insert
if ($f_id=="0") {
    $result=$db->query('insert into clients (surname,name, second_name, birthday, phone, address, email, photo, sign, confirmed, created) '.
        ' values ("?s","?s","?s",'.$birth_plh.',"?s","?s","?s","?s",'.$sign_plh.',?i,"'.date('Y-m-d H:i:s').'")',
        $f_surname,
        $f_name,
        $f_second_name,
        $f_birthday,
        $f_phone,
        $f_address,
        $f_email,
        $f_photo,
        $f_sign,
        $f_confirmed
    );
    if ($result==true) {
        $insert_id=$db->getLastInsertId();
        $arr=array('clientId' => $insert_id);
        echo json_encode($arr);
    } else {
        $arr=array('clientId' => 0);
        echo json_encode($arr);
    }
} else {
    $result=$db->query('update clients set '.
        'surname="?s", '.
        'name="?s", '.
        'second_name="?s", '.
        'birthday='.$birth_plh.', '.
        'phone="?s", '.
        'address="?s", '.
        'email="?s", '.
        'photo="?s", '.
        'sign='.$sign_plh.' '.
        'where (id=?s)',
        $f_surname,
        $f_name,
        $f_second_name,
        $f_birthday,
        $f_phone,
        $f_address,
        $f_email,
        $f_photo,
        $f_sign,
        $f_id
    );
    $arr=array('clientId' => $f_id);
    echo json_encode($arr);
}

?>
