"use strict";
 var OldClient = new Object ;	// Данные о клиенте, полученные из БД
var Client = new Object;	// В этом объекте текущие данные о клиенте из полей ввода
var covidCertValidated=false;

//(function() {
  var _loader;
  //var _resultFormatter;
  var ExecResultEnum = Object.freeze({
    ok: 1,
    ajaxError: 2,
    resultError: 3
  });
  var _currentCmd;
  var _ajaxresult;
  var _ajaxok;
  var CardNumber;
  var CardRegistered;
  var childrensList=Array();
  var clientsList=Array;
  var childsSelectedList = Array();
  var tempChildList = new Object; // Для сохранения списка детей без привязки к карте
  var resultAsyncFunc;
  var stepNum;
  var lastActtm;
  var countSelectedChilds=0;
  var isNotRegistered=false;
  var isNeedSaveClientSign=false;
  var has_photo=false;
  var rulesId=0;
  var stepCount=3;
  var currChildNum;
  
  const timeToReload = 5;
  const viewDebugAjax=false;
  const waitingActivitySeconds=300;
  const viewKeyboard=true;
  const placeholder="_";
	
	// Преобразовать первый символ в заглавные
	function ucFirst(str) {
	  // только пустая строка в логическом контексте даст false
	  if (!str) return str;

	  return str[0].toUpperCase() + str.slice(1);
	}
	// Делает заглавной первую букву каждого слова
	// Удаляет лишние пробелы
	function fioUpperCase(fio) {
		var arrD=fio.split(" ");
		for (var i=0; i<arrD.length; i++) {
			if (arrD[i].length==0) {
				arrD.splice(i,1);
				--i;
			} else {
				arrD[i]=ucFirst(arrD[i]);
			}

		}
		return arrD.join(" ");
	}
	
	function copyObject(source,dest) {
		for ( var key in source) {
			dest[key]=source[key];
		}
	}
	
	function setActivity() {
		lastActtm= new Date().getTime();
	}
	
	// Очистка данных анкеты
	function ClearForm() {
		$(".form-control").val("");
		//childrensList=Null;
		
	}
	
	function checkActivity() {
		if ((new Date().getTime() - lastActtm) > (waitingActivitySeconds*1000)) {
			document.location.reload();
		}
		/*
		// Проверяем, не на начальном ли экране
		if (!$("#slideStart").hasClass("visible")) {
			// Если с момента активности прошло больше waitingActivitySeconds, то перезагружаем страницу

		}*/
	}
	
  function setElemVisibility(element, visible) {
    if (visible === true) {
      $(element).removeClass("invisible");
		$(element).removeClass("invisible1");
      $(element).addClass("visible");
    } else {
      $(element).removeClass("visible");
      $(element).addClass("invisible");
    }
  }
  function setVisible(element) {
	  setElemVisibility(element,true)
  }
  
  function setInvisible(element) {
	  setElemVisibility(element,false)
  }
  
  function clearErrors() {
	  $("#errormsg").text("");
	  $("#errorcontainer").hide();
	  $(".errorinput").empty();
  }
  
  function printError(msg,element) {
		if (element !== undefined) {
			$(element).html(msg);
		}else {
			$("#errorcontainer").show();
			$("#errormsg").append("<p>"+msg+"</p>")
		}
  }

  function printCriticalError(msg) {
		$("body").append("<div id='criticalError'>"+msg+"</div>");
		setTimeout(function(){location.reload()},timeToReload*1000);
  }


  function hideKeyboard() {
	  var element=$("#keyboard-container").first();
	  setInvisible(element);
	  $(".wrapper").removeClass("paddingkeyboard");
  }
  
  function getKeyboard(elemid) {
	  $("#keyboard").removeData();
	  switch (elemid) {
		  case 'CardNumber':
		  case 'OwnerBirthday':
		  case 'OwnerPhone':
		  case 'ChildBirthday':
			$("#keyboard").jkeyboard({
				layout:"numbers_only1",
				input: $("#"+elemid)
			});
			break;
		  case 'OwnerEmail':
			$("#keyboard").jkeyboard({
				layout:"email",
				input: $("#"+elemid)
			});
			break;
		  case 'OwnerFamily':
		  case 'OwnerName':
		  case 'OwnerSecondName':
		  case 'ChildFIO':
			  $("#keyboard").jkeyboard({
				  layout:"russianOnly",
				  input: $("#"+elemid),
				  firstUpper: true
			  });
		  default:
			$("#keyboard").jkeyboard({
				layout:"russian1",
				input: $("#"+elemid)
			});
	  }
	  $("#"+elemid).trigger("focus");
	  var element=$("#keyboard-container").first();
	  $(".wrapper").addClass("paddingkeyboard");
	  setVisible(element);
  }
  
  function onAjaxErr() {
    _ajaxok=false;
	_ajaxresult=""
  }

  function onAjaxOk(resultMsg) {
    _ajaxok=true;
	_ajaxresult=resultMsg;
  }

  
  function checkCardData(num) {
	if (isNaN(num)) {return false;}
	if (String(num).length != 6) {return false;}
	return true;
  }
  
  function displayClientInfo(resultMsg) {
        if (!("surname" in resultMsg)) {resultMsg.surname="";}
      if (!("name" in resultMsg)) {resultMsg.name="";}
      if (!("second_name" in resultMsg)) {resultMsg.second_name="";}
      if (!("birthday" in resultMsg)) {resultMsg.birthday="";}
      if (!("phone" in resultMsg)) {resultMsg.phone="";}
      if (!("address" in resultMsg)) {resultMsg.address="";}
      if (!("email" in resultMsg)) {resultMsg.email="";}
      if (!("photo" in resultMsg)) {resultMsg.photo="";}
      if (!("sign" in resultMsg)) {resultMsg.sign="";}
		copyObject(resultMsg,OldClient);
        copyObject(resultMsg,Client);
		// Вывод информации о владельце карты
		$("#OwnerFamily").val(OldClient.surname);
		$("#OwnerName").val(OldClient.name);
		$("#OwnerSecondName").val(OldClient.second_name);
		$("#OwnerBirthday").val(OldClient.birthday);
		$("#OwnerPhone").val(printPhone(OldClient.phone));
		$("#OwnerAddress").val(OldClient.address);
		$("#OwnerEmail").val(OldClient.email);
        var canvas=$("#photo")[0];
        var ctx=canvas.getContext('2d');
		if (OldClient.photo!="") {
		    var img=new Image();
		    img.src=OldClient.photo;
            ctx.drawImage(img,0,0);
            has_photo=true;
        } else {
            ctx.clearRect(0, 0, canvas.width, canvas.height);
            has_photo=false;
        }

  }
  function displayChildrensList(resultMsg) {
	  if (_ajaxok==false) printCriticalError('Ошибка поиска детей. Дальнейшее выполнение невозможно');
    else {
		childrensList=resultMsg;
		// Вывод информации о ранее введенных детях
		if (Array.isArray(childrensList) && (childrensList.length>0)) {
			// Выводим список детей
			
			$("#ChildsList").empty();
			var tempChild;
			var i=0;
			var clsSel;
			countSelectedChilds=0;
			while (i < childrensList.length) {
				if (childrensList[i].selected) {clsSel="chl_sel_on"} else {clsSel="chl_sel_off"}
				$("#ChildsList").append("<tr>" +
					"<td class='chl_num'>"+String(i+1)+"</td>" +
					"<td class='chl_data'><a href=\"javascript:void(0);\" class=\"anc\" id=\"aChild"+String(i)+"\">"+childrensList[i].fio+" "+childrensList[i].birthday+" г. р.</a></td>" +
					"<td class='chl_sel'><a id='sChild"+String(i)+"' href='javascript:void(0)' class='"+clsSel+"'>да</a></td>" +
					"<td class='chl_edit'><a href='javascript:void(0)' id=\"eChild"+String(i)+"\"></a></td></tr>")
				if (childrensList[i].selected) {++countSelectedChilds;}
				$("#aChild"+String(i)).click(changeSelectChild);
				$("#sChild"+String(i)).click(changeSelectChild);
				$("#eChild"+String(i)).click(function(){
					var elemid=$(this).attr("id");
					var num=elemid.substring(6);
					currChildNum=num;
					// Редактируем данные ребенка
					$("#ChildID").val(childrensList[num].id);
					$("#ChildFIO").val(childrensList[num].fio);
					$("#ChildBirthday").val(childrensList[num].birthday);
					showFormAddChild();
				});
				++i;
			}
		} else {
			$("#ChildsList").text("По данной карте ранее не были введены данные о детях");
		}
	}
  }
  
  function showFormAddChild() {
		clearErrors();
		setVisible(document.getElementById("ChildEdit"));
	  setInvisible(document.getElementById("AddChild"));
  }
  function hideFormAddChild() {
	  setInvisible(document.getElementById("ChildEdit"));
	  setVisible(document.getElementById("AddChild"));
	  $('.bottom-center').children().removeClass("visible");
	  $('.bottom-center').children().addClass("invisible");
  }
  
  function closeFormAddChild() {
	  $("#ChildFIO").val("");
	  $("#ChildBirthday").val("");
	  hideFormAddChild();
  }
  
	function printStepNumber(stepn) {
		if (stepn>0) {$("#stepNumber").text("Шаг "+stepn+" из "+stepCount)} else {$("#stepNumber").text("")};
	}
	
	function correctChildData(name1, birth ) {
		var f=true;
		if (name1 !== undefined) {
			var arr=name1.split(" ");
			if (arr.length<2) {
				f=false;
			} else {
				var a;
				for ( a in arr) {
					if (arr[a].length<2) {f=false}
				}
			}
		} else {
			f=false;
		}
		if (f==false) {
			printError("Неверно введено ФИО ребенка. Укажите ФИО полностью",document.getElementById("ChildFIOErr"));
		}
		if (isValidChildrenBirthday(birth)==false) {
			f=false;
			printError("Неверно указана дата. Дата должна быть указана в формате дд.мм.гггг. Возраст детей должен быть не больше 18 лет.",document.getElementById("ChildBirthdayErr"));
		}
		return f;
	}
	// Проверяет по id, не выбран ли уже такой ребенок
	function childSelected(children) {
		for ( var ch in childsSelectedList) {
			if ((childsSelectedList[ch] != null) && (children.id === childsSelectedList[ch].id)) {
				return true;
			}
		}
		return false;
	}
	// Функция отображает количество выбранных детей
	function printCountSelectedChilds() {
		if (countSelectedChilds>0) {
			$("#ChildrensCountInfo").removeClass("text-danger");
			$("#ChildrensCountInfo").addClass("text-success");
		} else {
			$("#ChildrensCountInfo").removeClass("text-success");
			$("#ChildrensCountInfo").addClass("text-danger");
		}
		$("#ChildrensCount1").text(String(countSelectedChilds));
	}
	function changeSelectChild() {
		var elemid=$(this).attr("id");
		var num=elemid.substring(6);
		if (isNumeric(num) && (num<childrensList.length)) {
			if (childrensList[num].selected) {
				childrensList[num].selected=false;
				$("#sChild"+num).removeClass("chl_sel_on");
				$("#sChild"+num).addClass("chl_sel_off");
				--countSelectedChilds;
			} else {
				childrensList[num].selected=true;
				$("#sChild"+num).removeClass("chl_sel_off");
				$("#sChild"+num).addClass("chl_sel_on");
				++countSelectedChilds;
			}
			printCountSelectedChilds();
		}
	}

  async function execCmd(buttonId, cmd) {
    $("#loading-overlay").show();
	try {
	  await cmd();
    } catch (error) {
      $("#loading-overlay").hide();
    } finally {
      $("#loading-overlay").hide();
    }
  }

  async function getCardRegister() {
	 _currentCmd = commandCardInfo; 
	_ajaxok=false;
	_ajaxresult=null;
	CardRegistered=false;
	if (CardNumber !== undefined) {
		await execCmd("Step1OK", async function() {
		  await _loader.sendQueryGet(["cards"], { n: CardNumber }, onAjaxOk, onAjaxErr);
		});
	}
	if (viewDebugAjax==true) {$("#debugmsg").append(JSON.stringify(_ajaxresult, null, "  "));}
	if ((_ajaxok==true) && (_ajaxresult.errors.length==0))  {CardRegistered=true} else {CardRegistered=false}
  }

  async function loadChildrensList(cardNum) {
	await execCmd("", async function() {
      if (cardNum !== undefined) {
		  await _loader.sendQueryGet(["getChildrensList.php"], { cardnum: cardNum }, onAjaxOk, onAjaxErr);
		//if (viewDebugAjax==true) {$("#debugmsg").append(JSON.stringify(_ajaxresult, null, "  "));}
		displayChildrensList(_ajaxresult);
	  }
    });
	printCountSelectedChilds();
  }
  
  async function saveChild(cliid,childInfo) {
	    var id1;
		await execCmd("", async function() {
            await _loader.sendQueryPost(["saveChild.php"], {}, onAjaxOk, onAjaxErr,childInfo);
            id1=_ajaxresult.childId;
            if ((_ajaxok!=true) || (id1<1)) {
                printCriticalError('Ошибка при сохранении данных ребенка. Дальнейшая работа невозможна.');
                return 0;
            }
            if (isNumeric(childInfo.id)) {var idold=childInfo.id} else {var idold=0}
		        if (idold < 1) {
                    var f=await _loader.sendQueryPost(["addChildToClient.php"], {}, onAjaxOk, onAjaxErr,{clientid:cliid, childid:id1});
                    if (f==0) {
                        return 0;
                    }
		        }
	  });
	    return id1;
  }
  
async function editChild() {
	setActivity();
	clearErrors();
	var countchilds=childrensList.length;
	var childid=$("#ChildID").val();
	var fio=fioUpperCase($("#ChildFIO").val());
	var birthday=$("#ChildBirthday").val();
	if (correctChildData(fio,birthday)==true){
		var tempChild = new Object;
		if (isNaN(childid)) {tempChild.id=""} else {tempChild.id=childid;}
		tempChild.fio=fio;
		tempChild.birthday=birthday;
		if (!isNotRegistered) {
			var f = await saveChild(Client.id,tempChild);
			if (f>0) {
				if (tempChild.id=="") {
					tempChild.id=f;
				}
			} else {
				return false;
			}
		}
		hideFormAddChild();
		// Если номер меньше, чем количество элементов, то редактирование данных, иначе добавление
		if (currChildNum<childrensList.length) {
			childrensList[currChildNum].fio=tempChild.fio;
			childrensList[currChildNum].birthday=tempChild.birthday;
			displayChildrensList(childrensList);
		} else {
			childrensList.push(tempChild);
			displayChildrensList(childrensList);
			// Выполняем выбор добавленного ребенка
			$("#aChild"+currChildNum).click();
		}

	}
  }
  
  function addChild() {
	 setActivity();
	 currChildNum=childrensList.length;
	 $("#ChildID").val("");
	 $("#ChildFIO").val("");
	 $("#ChildBirthday").val("");
	 showFormAddChild();
  }

async function getRules() {
	await _loader.sendQueryGet(["getRules.php"],{}, onAjaxOk,onAjaxErr);
	if (_ajaxok ==true) {
		var rules=_ajaxresult;
		rulesId=rules.id;
	} else { printCriticalError("Не удалось получить правила нахождения в БД. Дальнейшее заполнение формы невозможно")}
	if (isNumeric(rulesId) & (rulesId>0)) {
		// Записываем правила в блок вывода
		$("#rules").html(rules.rules);
	} else {
		printCriticalError("В базе данных не найдены правила нахождения в развлекательном центре. Дальнейшее заполнение формы невозможно")
	}
}

// Если у пользователя еще нет карты
function StartNoCard() {
	isNotRegistered=true;
	stepCount=5;
        if (checkCovidCert==true) {stepCount++;}
	Client.id=0;
	setActivity();
	hideKeyboard();
	clearErrors();
	CardNumber=0;
	ClearForm();
	showSlideData('slideOwnerFIO');
	setVisible($("#bottom-panel")[0]);
	$(document).off('keypress');
	printStepNumber(++stepNum);
	// Получаем правила из БД
	getRules();
}

function checkOwnerFIOData() {
	var f=true;
	var str=$("#OwnerFamily").val();
	if ( (typeof str !== "string") || (str.length<2)) {
		printError("Не введена фамилия. Фамилия должна содержать не менее 2 символов",$("#OwnerFamilyErr").first());
		f=false;
	}
    $("#OwnerFamily").val(ucFirst($("#OwnerFamily").val()));
	str=$("#OwnerName").val();
	if ( (typeof str !== "string") || (str.length<2)) {
		printError("Не введено имя. Имя должно содержать не менее 2 символов", $("#OwnerNameErr").first());
		f=false;
	}
    $("#OwnerName").val(ucFirst($("#OwnerName").val()));
    $("#OwnerSecondName").val(ucFirst($("#OwnerSecondName").val()));
	str=getMaskedField($("#OwnerBirthday").val(),placeholder);
	if ((str.length>0) && (isValidBirthday(str)==false)) {
		printError("Неверно указана дата рождения. Дата рождения должна быть введена в формате дд.мм.гггг", $("#OwnerBirthdayErr").first());
		f=false;
	}
	if (f==true) {
		Client.surname=$("#OwnerFamily").val();
		Client.name=$("#OwnerName").val();
		Client.second_name=$("#OwnerSecondName").val();
		if (str.length>0) { Client.birthday=$("#OwnerBirthday").val(); } else { Client.birthday=""}
	}
	return f;
}

function printPhone(phone) {
	if (phone.length==11) {
		return '+'+phone.slice(0,1)+'('+phone.slice(1,4)+')'+phone.slice(4,7)+'-'+phone.slice(7,9)+'-'+phone.slice(9,11);
	} else { return phone;}
}
/*
function checkEmail(id_input) {
		var f=true;
		var str=$(id_input).val();
		if (str !== ""){
			var re = /^[\w]{1}[\w-\.]*@[\w-]+\.[a-z]{2,4}$/i;
			f = re.test(str);
		}
		return f;
}*/
function checkOwnerContactsData() {
	var f=true;
	var str=getMaskedField($("#OwnerPhone").val(),placeholder);
	if (str.length!==16) {
		printError("Неправильно введен номер телефона. Номер телефона должен состоять из 11 цифр. Например +7(999)999-99-99 или +7(472)599-99-99",$("#OwnerPhoneErr").first());
		f=false;
	}
	str=$("#OwnerAddress").val();
	if (str.length<10) {
		printError("Не введен адрес проживания. Адрес должен состоять не менее, чем из 10 символов",$("#OwnerAddressErr").first());
		f=false;
	}
	if (!checkEmail($("#OwnerEmail").val())) {
		printError("Неправильно введен адрес электронной почты. Введите правильный адрес E-mail. Например, primer@yandex.ru",$("#OwnerEmailErr").first());
		f=false;
	}
	if (f==true) {
		Client.phone=convertPhoneToDB($("#OwnerPhone").val());
		Client.address=$("#OwnerAddress").val();
		Client.email=$("#OwnerEmail").val();
	}
	return f;
}

function checkOwnerPhoto() {
	if (!has_photo) {printError("Сначала сделайте фото",$("#b_photoErr")[0]);}
	if (has_photo==true) {
		var canvas = document.getElementById('photo');
		Client.photo=canvas.toDataURL("image/png");
	}
	return has_photo;
}

function isNeedSave(olddata,newdata) {
	if (olddata.surname!==newdata.surname) {return true}
	if (olddata.name!==newdata.name) {return true}
	if (olddata.second_name!==newdata.second_name) {return true}
	if (olddata.birthday!==newdata.birthday) {return true}
	if (olddata.phone!==newdata.phone) {return true}
	if (olddata.address!==newdata.address) {return true}
	if (olddata.email!==newdata.email) {return true}
    if (olddata.photo!==newdata.photo) {return true}
	return false;
}

function writeOwnerInfo() {
	var needSave=false;
	// Проверяем корректность введенных данных о владельце
	TempOwner.first_name=ucFirst($("#OwnerName").val());
	TempOwner.last_name=ucFirst($("#OwnerFamily").val());
	TempOwner.middle_name=ucFirst($("#OwnerSecondName").val());
	TempOwner.birthday=getMaskedField($("#OwnerBirthday").val(),placeholder);
	TempOwner.gender=0;
	TempOwner.phone=getMaskedField($("#OwnerPhone").val(),placeholder);
	TempOwner.email=$("#OwnerEmail").val();
	TempOwner.address=$("#OwnerAddress").val();
	TempOwner.mailing_consent=true;
	var f=false;
	if (checkOwnerContactsData(TempOwner)==true) {
			f=true;
	}
	return f;
}


function writeClientDataToAnketa() {
	// В массиве выбранных детей могут быть пустые элементы. Проверяем массив и удаляем такие элементы
	var i=0;
	// Прописываем данные в анкету
	$("#aOwnerFIO").text(Client.surname+" "+Client.name+" "+Client.second_name);
	$("#aOwnerAddress").text(Client.address);
	$("#aOwnerPhone").text(printPhone(Client.phone));
	i=0;
	$("#childrens").empty();
	//if (childsSelectedList.length=0) { setInvisible(document.getElementById("Trust1")); } else { setVisible(document.getElementById("Trust1")); }
	childsSelectedList=[];
	for (i=0;i<childrensList.length;i++) {
		if (childrensList[i].selected) {
			$("#childrens").append("<li>"+childrensList[i].fio+" "+childrensList[i].birthday+" г. р.</li>");
			// Массив childsSelectedList нужен, чтобы не переписывать код отправки анкеты на сервер
			childsSelectedList.push(childrensList[i]);
		}
	}
	setInvisible(document.getElementById("ChildEdit"));
	return true;
}

async function ajax_getClientsList(cardnum) {
	await _loader.sendQueryGet(["clientsList.php"],{cardnum: cardnum},onAjaxOk,onAjaxErr);
	if (_ajaxok==true) {
		return _ajaxresult;
	} else {
		printCriticalError('Ошибка при получении списка клиентов. Дальнейшая работа невозможна');
	}
}

async function ajax_saveClientData(clientobj) {
	await _loader.sendQueryPost(["saveClientInfo.php"],{},onAjaxOk,onAjaxErr,clientobj);
	if  (_ajaxok==true) {
		return _ajaxresult.clientId;
	} else {
		return 0;
	}
}

/* Функция сохранения ребенка в БД
Параметры:
children - данные ребенка (FIO, birthday)
*/
async function ajax_saveChild(child) {
	await _loader.sendQueryPost(['saveChild.php'],{},onAjaxOk,onAjaxErr,child);
	if  (_ajaxok==true) {
		return _ajaxresult.childId;
	} else {
		return 0;
	}
}

async function addChildToClient(clientid,childid) {
	var obj= new Object;
	obj.clientid=clientid;
	obj.childid=childid;
	await _loader.sendQueryPost(['addChildToClient.php'],{},onAjaxOk,onAjaxErr,obj);
	if  ((_ajaxok==true) && (_ajaxresult==1)) {
		return true;
	} else {
		return false;
	}
}

async function ajax_addVisit(clientId,cardNumber,rulesId,childrens) {
	if ((clientId<1) || (rulesId<1)) {
		return false;
	}
	var json1= new Object;
	var arr=[];
	for (var i=0; i<childrens.length;i++) { arr.push(childrens[i].id); }
	json1.clientId=clientId;
	json1.cardNumber=cardNumber;
	json1.rulesId=rulesId;
	json1.childrens=arr;
	await _loader.sendQueryPost(['addVisit.php'],{},onAjaxOk,onAjaxErr,json1);
	if  ((_ajaxok==true) && (_ajaxresult==1)) {
		return true;
	} else {
		return false;
	}
}

async function ajax_addClientCard(clientid,cardnum) {
    var obj= new Object;
    obj.clientid=clientid;
    obj.cardnum=cardnum;
    await _loader.sendQueryPost(['addClientCard.php'],{},onAjaxOk,onAjaxErr,obj);
    if  ((_ajaxok==true) && (_ajaxresult==1)) {
        return true;
    } else {
        return false;
    }
}

function removeNullElements(arr) {
	var newarr=[];
	for (var i=0;i<arr.length;i++) {
		if (arr[i]!=null) {newarr.push(arr[i]);}
	}
	return newarr;
}

async function sendAnketa() {
	setActivity();
	clearErrors();
	hideKeyboard();
	var isAgree=$("#checkConfirm").prop("checked");
	if (isAgree==true) {
		// Удаляем из массива выбранных детей пустые записи
		childsSelectedList=removeNullElements(childsSelectedList);
		await execCmd("",async function(){
			if (isNotRegistered==true) {
				// Сохранение данных о клиенте
				var a = await ajax_saveClientData(Client);
				if (a<1) {
					printCriticalError("Ошибка сохранения информации данных пользователя в БД");
					return;
				}
				Client.id=a;
				var tempChild=new Object;
				// Для незарегистрированных клиентов сохраняем данные о детях
				for (var i=0;i<childrensList.length;i++) {
					copyObject(childrensList[i],tempChild);
					tempChild.id=0;
					a= await ajax_saveChild(tempChild);
					if (a<1) {
						printCriticalError("Ошибка сохранения информации данных ребенка в БД");
						return;
					} else {
						// Обновляем id ребенка после сохранения в БД
						childrensList[i].tempId=childrensList[i].id;
						childrensList[i].id=a;
						// После добавления ребенка создаем связь между ребенком и клиентом
						a = await addChildToClient(Client.id,childrensList[i].id);
					}

				}
				// В списке выбранных детей проставляем правильные Id после сохранения в БД
				var id1=0;
				var j=0;
				// Обновляем id в списке выбранных детей
				for (i=0;i<childsSelectedList.length;i++) {
					id1=childsSelectedList[i].id;
					// Ищем id в списке детей
					for (j=0;j<childrensList.length;j++) {
						if (childrensList[j].tempId==id1) {
							childsSelectedList[i].id=childrensList[j].id;
							break;
						}
					}
				}
			} else {
				if (isNeedSaveClientSign) {
					var a = await ajax_saveClientData(Client);
					if (a<1) {
						printCriticalError("Ошибка сохранения информации данных пользователя в БД");
						return;
					}
				}
			}
			// Создаем визит клиента
			await ajax_addVisit(Client.id,CardNumber,rulesId,childsSelectedList);

		})
		// Если визит успешно создан, то отображаем пользователю слайд об успешном добавлении и перезагружаем страницу
		if ((_ajaxok==true)&&(_ajaxresult==1)) {
			stepNum=0;
			showSlideData("slideSuccess");
			// Перезагружаем страницу
			setTimeout("document.location.reload()",5000);
		} else {
			printCriticalError("Ошибка сохранения посещения в БД");
			return;
		}
	} else {
		printError("Сначала согласитесь с правилами", $("#checkConfirmErr").first());
	}
}

async function ProcessData(func,nextSlide) {
	setActivity();
	clearErrors();
	hideKeyboard();
	var currSlide=$(".visible");
	var f=await func();
	if (f==true) {
		++stepNum;
		showSlideData(nextSlide.id);
	}
}
function GoToSlide(nextSlide) {
	setActivity();
	hideKeyboard();
	var currSlide=$(".visible");
	setInvisible(currSlide);
	setVisible(nextSlide);
	printStepNumber(--stepNum);
	if (nextSlide[0].id=="slideStart") {
		$(document).on('keypress',document,getCard);
		setInvisible($("#bottom-panel")[0]);
		setVisible($(".cubes-top")[0]);
		setVisible($(".cubes-bottom")[0]);
	}
}
// Функция выбора
function selectClient(num) {
	if (num<clientsList.length) {
		copyObject(clientsList[num],Client);
		$('#cls_FIO').text(Client.surname+' '+Client.name+' '+Client.second_name);
		$('#cls_birthday').text(Client.birthday);
		$('#cls_phone').text(printPhone(Client.phone));
		$('#cls_address').text(Client.address);
		$('#cls_email').text(Client.email);
		$('.clientSelected').removeClass('clientSelected');
		$('#cs_'+num).addClass('clientSelected');
		setVisible($("#sl_ClientSelect_Edit")[0]);
		setInvisible($("#substep1")[0]);
		setVisible($("#substep2")[0]);
		setVisible($("#substep3")[0]);
		clearErrors();
                covidCertValidated=false;
	}
}

function displayClientsList() {
	$('#sl_ClientSelect_Card').text(CardNumber);
	// Очищаем блок с клиентами
	$('.clientSelect').detach();
	for (var i=0;i<clientsList.length;i++) {
		var html='<a href="javascript:void(0);" id="cs_'+i+'" class="clientSelect"><div>' +
			'<img src="'+clientsList[i].photo+'">'+'' +
			'<span>'+clientsList[i].surname+' '+clientsList[i].name+' '+clientsList[i].second_name+'</span>'+
			'</div></a>';
		$('#sl_ClientSelect_Add').before(html);
		$('#cs_'+i).click(function () {
			var elemid=$(this).attr("id");
			var num=elemid.substring(3);
			selectClient(num);
		})
	}
	Client.id=0;
    $('#cls_FIO').text("");
    $('#cls_birthday').text("");
    $('#cls_phone').text("");
    $('#cls_address').text("");
    $('#cls_email').text("");
}

async function startWithCard() {
	// Если введен номер в поле cardNum
	var cardNum=$("#cardNum").val();
	setActivity();
	clearErrors();
	hideKeyboard();
	stepCount=3;
        if (checkCovidCert==true) {++stepCount;}
	if ((cardNum)&&(cardNum.length==6)) {CardNumber=cardNum;}
	if (CardNumber.length==6) {
		await execCmd("",async function () {
			clientsList=await ajax_getClientsList(CardNumber);
			if (clientsList.length==0) {
				stepCount=stepCount+2;
				++stepNum;
				Client.id=0;
				showSlideData('slideOwnerFIO');
			} else {
				++stepNum;
                displayClientsList();
				showSlideData('slideClientSelect');
			}
            // Получаем правила из БД
            await getRules();
		})
        $(document).off('keypress');
	}
}

function getCard(e) {
	var cardnum=readCard(e);
	if (cardnum.length==6) {
		CardNumber=cardnum;
		startWithCard();
	}
}

async function clientSelectOK() {
	if ((Client.id==undefined)||(Client.id<1)) {
		printError('Сначала выберите клиента',$('#clientSelectErr').first());
		return false;
	}
	await loadChildrensList(CardNumber);
	return true;
}

function newClient() {
    Client.id=0;
    Client.surname="";
    Client.name="";
    Client.second_name="";
    Client.birthday="";
    Client.phone="";
    Client.address="";
    Client.email="";
    Client.photo="";
    Client.sign="";
    stepCount=6;
    displayClientInfo(Client);
    return true;
}
function editClient() {
    if (Client.id>0) {
        displayClientInfo(Client);
        stepCount=6;
        return true;
    } else {
        printError("Перед редактированием необходимо выбрать клиента",$("#clientSelectErr")[0]);
        return false;
    }

}

async function finishWriteOwnerInfo() {
    if (checkOwnerPhoto()==false) {return false}
    if (!isNotRegistered) {
        if ((Client.id==0) || (isNeedSave(OldClient,Client))) {
            Client.confirmed=1;
            await execCmd("",async function () {
                var isAdd=(Client.id==0);
                var cliid=await ajax_saveClientData(Client);
                if (cliid>0) {
                    Client.id=cliid;
                    copyObject(Client,OldClient);
                    if (isAdd==true) {
                        var f = await ajax_addClientCard(cliid,CardNumber);
                        if (f!=true) {
                            printCriticalError("Не удалось добавить карту клиента. Дальнейшая работа приложения невозможна");
                            return;
                        }
                    }
                } else {
                    printCriticalError("Не удалось сохранить данные клиента. Дальнейшая работа приложения невозможна");
                    return;
                }
            })

        }
        await loadChildrensList(CardNumber);
    }
    printCountSelectedChilds();
    return true;
}
function printSign(dURL,id) {
		var img= new Image();
		img.src=dURL;
		img.style.width="150px";
		$("#"+id).empty();
		$("#"+id).append(img);
}

function checkSign() {
	var cb=$("#checkConfirm")[0];
	if (cb.checked)  {
		if (useSign==true) {

			if ((stepCount<5)&&(Client.sign)&&(Client.sign.length>0)) {
				// Отображение подписи
					printSign(Client.sign,"sign");
			} else {
				cb.checked=false;
				// Вывод окна ввода подписи
				//setVisible($("#paintSign")[0]);
				clearErrors();
				$("#paintSign").modal('show');
				$("#sign_clear").click();
				startdraw("canvasSign");
			}
		}
	} else {
		// Удаляем подпись с панели
		$("#sign").empty();
	}

}

async function signOK() {
	clearErrors();
	//Проверяем размер подписи. Размер должен быть не менее 100 пикселей на 100
	var dURL=getDataURLfromCanvas("canvasSign");
	if (dURL.length>0) {
		Client.sign=dURL;
		if (!isNotRegistered) {
			isNeedSaveClientSign=true;
		}
		$("#paintSign").modal('hide');
		printSign(dURL,"sign");
		$("#checkConfirm")[0].checked=true;
	} else {
		printError("Слишком маленькая подпись. Подпись должна быть крупнее",$("#canvasSign")[0]);

	}
}

function hideSlide(slide,toleft) {
	$(slide).removeClass('slideInLeft slideInRight visible ha');
	if (toleft) {var cls='slideOutLeft'} else {var cls='slideOutRight'}
	$(slide).addClass(cls);
	setTimeout(function(){$(slide).addClass('h0')},2000);
}
function showSlide(slide,fromright) {
	$(slide).removeClass('slideOutLeft slideOutRight invisible h0');
	if (fromright) {var cls="slideInRight"} else {var cls="slideInLeft"}
	$(slide).addClass(cls+' visible ha');
}

function showSlideData(nextSlideId, movenext=true) {
	$('.bottom-center').children().removeClass("visible");
	$('.bottom-center').children().addClass("invisible");
	var currSlide=$(".slide").filter(".visible")[0];
	var nextSlide=$("#"+nextSlideId)[0];
	hideSlide(currSlide,movenext);
	//setInvisible(currSlide);
	switch (currSlide.id) {
		case "slideStart":
			setVisible($("#bottom-panel")[0]);
			setInvisible($(".cubes-top")[0]);
			setInvisible($(".cubes-bottom")[0]);
			setInvisible($("#sl_ClientSelect_Edit")[0]);
			break;
		case "slideClientSelect":
			setInvisible($("#substep3")[0]);
			break;
		case "slideChildrens":
			hideFormAddChild();
			break;
	}
	switch (nextSlideId) {
		case "slideStart":
			setInvisible($("#bottom-panel")[0]);
			setVisible($(".cubes-top")[0]);
			setVisible($(".cubes-bottom")[0]);
			break;
		case "slideClientSelect":
			if (Client.id>0) {
				setInvisible($("#substep1")[0]);
				setVisible($("#substep2")[0]);
				setVisible($("#substep3")[0]);
			} else {
				setVisible($("#substep1")[0]);
				setInvisible($("#substep2")[0]);
				setInvisible($("#substep3")[0]);
			}
		case "slideOwnerFIO":
			$(".wrapper").addClass("wrapper-margin");
			$('.bottom-center').addClass("logo-center");
			break;
		case "slideOwnerPhoto":
			$('.bottom-center').removeClass("logo-center");
			setVisible($("#d_photo")[0]);
			break;
		case "slideChildrens":
			setInvisible($("#sendProfile")[0]);
			setVisible($("#b-next-step")[0]);
			$('.bottom-center').addClass("logo-center");
			break;
		case "slideRules":
			$('.bottom-center').removeClass("logo-center");
			setVisible($("#confirm1")[0]);
			setInvisible($("#b-next-step")[0]);
			setVisible($("#sendProfile")[0]);
			break;
		case "slideSuccess":
			setInvisible($("#bottom-panel")[0]);
			setVisible($(".cubes-top")[0]);
			setVisible($(".cubes-bottom")[0]);
			break;
		default:
			$('.bottom-center').addClass("logo-center");
	}
	showSlide(nextSlide,movenext);
	printStepNumber(stepNum);
}
async function goToNextStep() {
	setActivity();
	clearErrors();
	hideKeyboard();
	var currSlide=$(".slide").filter(".visible")[0];
	var currSlideId=currSlide.id;
	switch (currSlideId) {
		case "slideClientSelect":
			var func=clientSelectOK;
			var nextSlideId="slideChildrens";
			break;
		case "slideOwnerFIO":
			var func=checkOwnerFIOData;
			var nextSlideId="slideOwnerContacts";
                        covidCertValidated=false;
			break;
		case "slideOwnerContacts":
			var func=checkOwnerContactsData;
			var nextSlideId="slideOwnerPhoto";
			break;
		case "slideOwnerPhoto":
			var func=finishWriteOwnerInfo;
			var nextSlideId="slideChildrens";
			break;
		case "slideChildrens":
			var func=writeClientDataToAnketa;
			if (checkCovidCert==true) {var nextSlideId="slideCovidCert"} else {var nextSlideId="slideRules";}
			break;
		case "slideCovidCert":
                        var func=function() {return covidCertValidated;};
			var nextSlideId="slideRules";
                        break;
                case "slideRules":
			var func=function() {return false;};
			var nextSlideId="slideSuccess";
		default:
			return false;
	}
	var f=await func();
	if (f==true) {
		++stepNum;
		showSlideData(nextSlideId);

	}
}
function goToPrevStep() {
	setActivity();
	clearErrors();
	hideKeyboard();
	var currSlide=$(".slide").filter(".visible")[0];
	var currSlideId=currSlide.id;
	switch (currSlideId) {
		case "slideClientSelect":
			var nextSlideId="slideStart";
			break;
		case "slideOwnerFIO":
			if ((isNotRegistered==true) || (clientsList.length==0)) {var nextSlideId="slideStart"} else {var nextSlideId="slideClientSelect"};
			break;
		case "slideOwnerContacts":
			var nextSlideId="slideOwnerFIO";
			break;
		case "slideOwnerPhoto":
			var nextSlideId="slideOwnerContacts";
			break;
		case "slideChildrens":
			if (stepCount<5) {var nextSlideId="slideClientSelect";} else {var nextSlideId="slideOwnerPhoto"};
			break;
                case "slideCovidCert":
                        var nextSlideId="slideChildrens";
                        break;
                case "slideRules":
			if (checkCovidCert==true) {var nextSlideId="slideCovidCert"} else {var nextSlideId="slideChildrens"};
			break;
		default:
			return false;
	}
	--stepNum;
	showSlideData(nextSlideId,false);
	if (nextSlideId=="slideStart") {
		$(document).on('keypress',document,getCard);
	}
}

  $(document).ready(function() {
    _loader = new LoaderUtils();
    // Создаем маски для полей ввода
	$("#OwnerBirthday").mask("99.99.9999");
	$("#CardNumber").mask("999999");
	$("#OwnerPhone").mask("+7(999)999-99-99");
	$("#ChildBirthday").mask("99.99.9999");
	// Прячем служебные элементы
	$("#errorcontainer").hide();
	$("#loading-overlay").hide();
	stepNum=0;
	// Функция перезагрузки страницы при отсутствии активности
	lastActtm = new Date().getTime();
	setInterval(checkActivity,10000);
	
	// Описываем обработчики событий
    //$("#startWriting").click(startWriting);
	$("#isNoCard").click(StartNoCard);
	$("#b-next-step").click(goToNextStep);
	$("#b-prev-step").click(goToPrevStep);
	// обработка данных от считывателя карт для первого слайда
	$(document).on('keypress',document,getCard);
    $("#sl_ClientSelect_Add").click(function(){ProcessData(newClient,$("#slideOwnerFIO")[0])});
    $("#sl_ClientSelect_Edit").click(function(){ProcessData(editClient,$("#slideOwnerFIO")[0])});
    $("#b_photo").click(function(){
	  	takePhoto();
		  has_photo=true;
    });
	$("#checkConfirm").click(checkSign);
	$("#sign_clear").click(function(){clear_canvas('canvasSign')});
	$("#sign_ok").click(signOK);
	$("#AddChild").click(addChild);
	$("#SaveChild").click(editChild);
	$("#CloseChild").click(closeFormAddChild);
	$("#sendProfile").click(sendAnketa);
	// Обработчик отображения клавиатуры
	if (viewKeyboard) {
		$(".form-control").click(function(){
			var elemid=$(this).attr("id");
			getKeyboard(elemid);
		})
	}
	
	// Отображение поля ввода карты для тестов
	  var str='<div><label for="cardNum">Номер карты</label>'+
		  '<input type="text" id="cardNum" class="form-control">'+
		  '<input type="button" id="startCard" class="btn button-big" value="Найти карту"</div>';
	  $("#slideStart").append(str);
	  $('#cardNum').mask("999999");
	  $('#startCard').click(startWithCard);
	
  });
//})();
