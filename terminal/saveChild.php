<?php
/*
 Сохранение данных о ребенке в БД
Параметры
$id - если не 0, то делаем Update, а если 0, то insert
$fio - обязательный
$birthday - обязательный. Формат дд.мм.гггг
Результат: id ребенка в таблице Childrens или 0, если не удалось сохранить данные
 */
require_once("Controller.php");

extract($_POST,EXTR_PREFIX_ALL,'f');
if (!isset($f_id) || !isset($f_fio) || !isset($f_birthday)) {
    $arr=array('childId' => 0);
    echo json_encode($arr);
    exit();
}
$f_birthday=date('Y-m-d',strtotime($f_birthday));
if (($f_id=="0") || ($f_id=="")) {
    $result=$db->query('insert into childrens (fio, birthday) '.
        ' values ("?s","?s")', $f_fio, $f_birthday);
    if ($result==true) {
        $insert_id=$db->getLastInsertId();
        $arr=array('childId' => $insert_id);
        echo json_encode($arr);
    } else {
        $arr=array('childId' => 0);
        echo json_encode($arr);
        exit();
    }
} else {
    $result=$db->query('update childrens set fio="?s", birthday="?s" where id=?s',$f_fio,$f_birthday,$f_id);
    $arr=array('childId' => $f_id);
    echo json_encode($arr);
}
?>
