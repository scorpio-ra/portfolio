function replaceAll(str, search, replacement) {
    return str.split(search).join(replacement);

}

function getMaskedField(value,plholder) {
    return replaceAll(value,plholder,"");
}

function isNumeric(n) {

    return !isNaN(parseFloat(n)) && isFinite(n);

    // Метод isNaN пытается преобразовать переданный параметр в число.
    // Если параметр не может быть преобразован, возвращает true, иначе возвращает false.
    // isNaN("12") // false
}
function convertStrToDate(value) {
    if (value==undefined) {return "";}
    var arrD = value.split(".");
    if (arrD.length<3) {return "";}
    arrD[1] -= 1;
    var d = new Date(arrD[2], arrD[1], arrD[0]);
    if ((d.getFullYear() == arrD[2]) && (d.getMonth() == arrD[1]) && (d.getDate() == arrD[0])) {
        return d;
    } else {
        return false;
    }
}

function convertPhoneToDB(value) {
    if (value.length>11) {
        value=replaceAll(value,'+','');
        value=replaceAll(value, '(','');
        value=replaceAll(value,')','');
        value=replaceAll(value,'-','');
    }
    return value;
}

function ConvertStrDateToJSON(dtstr) {
    if (value==undefined) {return 0;}
    if (isValidDate(dtstr)==true) {
        var arrD = value.split(".");
        arrD.forEach( function(val,num,arr) {
            if (val.length=1) {arr[num]='0'+arr[num]}
        })
        return arrD[2]+'-'+arrD[1]+'-'+arrD[0];
    } else {return 0;}
}
function formatDate(date) {
    var dt= new Date(date);
    var dd = dt.getDate();
    var mm = dt.getMonth() + 1;
    var yyyy = dt.getFullYear();
    if (isNaN(dd) || isNaN(mm) || isNaN(yyyy)) { return "";}
    if (dd < 10) dd = '0' + dd;
    if (mm < 10) mm = '0' + mm;
    return dd + '.' + mm + '.' + yyyy;
}

function isValidDate(value)
{
    if (value==undefined) {return false;}
    var arrD = value.split(".");
    if (arrD.length<3) {return false;}
    arrD[1] -= 1;
    var d = new Date(arrD[2], arrD[1], arrD[0]);
    if ((d.getFullYear() == arrD[2]) && (d.getMonth() == arrD[1]) && (d.getDate() == arrD[0])) {
        return true;
    } else {
        return false;
    }
}

// Проверка, является ли строка корректной датой рождения
function isValidBirthday(value) {
    if (isValidDate(value)) {
        var dt = convertDatetoJSON(value);
        var dtnow= new Date();
        if (dt>dtnow) { return false }
    } else { return false }
    return true;
}

function isValidChildrenBirthday(value) {
    if (isValidBirthday(value)) {
        var dt= convertDatetoJSON(value);
        var dtnow= new Date();
        var dtyear=dt.getFullYear();
        var dtmonth=dt.getMonth();
        var dtday=dt.getDate();
        var dtnowyear=dtnow.getFullYear();
        var dtnowmonth=dtnow.getMonth();
        var dtnowday=dtnow.getDate();
        if ((dtyear+18)<dtnowyear) {return false}
        if (((dtyear+18)==dtnowyear) && ((dtmonth*30)+dtday)<((dtnowmonth*30)+dtnowday)) {return false}
    } else { return false }
    return true;
}

function convertDatetoJSON(dtstr) {
    var arr=dtstr.split(".");
    var dt = new Date(arr[2],arr[1]-1,arr[0],3,0,0);
    return dt;
}

function checkEmail(val) {
    var f=true;
    var str=val;
    if (str !== ""){
        var re = /^[\w]{1}[\w-\.]*@[\w-]+\.[a-z]{2,4}$/i;
        f = re.test(str);
    }
    return f;
}