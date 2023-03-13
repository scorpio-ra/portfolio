var G_dirty = true;/*чтобы не посылать два раза один и тот же рисунок*/
var G_clear = true;/*чтобы не посылать два раза подряд пустой рисунок*/
var edge = new Object; // координаты правого нижнего и левого верхнего углов.
            // Нужны, чтобы перед сохранением отсечь неиспользуемую часть холста
function clearEdge(canv1) {
    edge.minX=canv1.width;
    edge.minY=canv1.height;
    edge.maxX=0;
    edge.maxY=0;
}

function checkEdge(x,y) {
    if (x>edge.maxX) {edge.maxX=x;}
    if (x<edge.minX) {edge.minX=x;}
    if (y>edge.maxY) {edge.maxY=y;}
    if (y<edge.minY) {edge.minY=y;}
}

function getCoords(elem) { // кроме IE8-
    var box = elem.getBoundingClientRect();

    return {
        top: box.top + pageYOffset,
        left: box.left + pageXOffset
    };

}

function startdraw(id) {
    //document.getElementById('confirm').disabled = false;
    /*Рисование на холсте*/
    var canv1 = document.getElementById(id);
    canv1.width=canv1.offsetWidth;
    canv1.height=canv1.offsetHeight;
    var ctx = canv1.getContext("2d");

    ctx.fillStyle = "black";

    var x;
    var y;
    var startx;
    var starty;
    clearEdge(canv1);

    canv1.addEventListener("touchstart",function(e) {
        // Перехватываем события только внутри нужного элемента
        // Для остальных генерируем нажатие на элемент
        //console.log(e);
        if (e.touches[0].target.id!=id) {
            var evt = new event("click");
            e.touches[0].target.dispatchEvent(evt);
            return;
        }
        e.preventDefault();
        e.stopPropagation();
        var e1=e.touches[0];
        var html = document.documentElement;
        var body = document.body;

        var html = document.documentElement;
        var body = document.body;
        var coord=getCoords(canv1);
        x = e1.clientX + (html && html.scrollLeft || body && body.scrollLeft || 0) - (html.clientLeft || 0)-coord.left;
        y = e1.clientY + (html && html.scrollTop || body && body.scrollTop || 0) - (html.clientTop || 0)-coord.top;

        ctx.beginPath();

        ctx.moveTo(x, y);
        G_dirty = true;
        G_clear = false;
        startx=x;
        starty=y;
    });

    document.addEventListener("touchend",function(e) {
        x = null;
        y = null;
        ctx.closePath();
    });

    document.addEventListener("touchmove",function(e) {
        if (x == null || y == null) {
            return;
        }
        var e = e || window.event;
        var e1=e.touches[0];
        e.preventDefault();
        e.stopPropagation();
        var html = document.documentElement
        var body = document.body
        var coord=getCoords(canv1);
        x = e1.clientX + (html && html.scrollLeft || body && body.scrollLeft || 0) - (html.clientLeft || 0)-coord.left;
        y = e1.clientY + (html && html.scrollTop || body && body.scrollTop || 0) - (html.clientTop || 0)-coord.top;

        ctx.lineTo(x, y);
        ctx.stroke();
        checkEdge(x,y);
        // Для первой линии нужно проверять еще начальную координату
        if ((startx>0)||(starty>0)) {
            checkEdge(startx,starty);
            startx=0;
            starty=0;
        }
        ctx.moveTo(x, y);

    });
};


function clear_canvas(id) {
    /*Проверка, чтобы не допустить полёта на сервер двух пустых картинок подряд. Бережём сервер*/
    if (G_clear) {
        return;
    }
    G_clear = true;
    G_dirty = true;

    var canv1 = document.getElementById(id);
    var context = canv1.getContext('2d');
    context.clearRect(0, 0, canv1.width, canv1.height);
    clearEdge(canv1);
}

function checkPaintSize() {
    //Проверяем размер подписи. Размер должен быть не менее 200 пикселей на 100
    if (((edge.maxX-edge.minX)>100)&&((edge.maxY-edge.minY)>100)) {return true;} else {return false;}
}

function getDataURLfromCanvas(id) {
    var canv1 = document.getElementById(id);
    var context = canv1.getContext('2d');

    if (checkPaintSize()) {
        var imgData=context.getImageData(edge.minX,edge.minY,edge.maxX-edge.minX, edge.maxY-edge.minY);
        var canv2 = document.createElement("canvas");
        canv2.width=edge.maxX-edge.minX;
        canv2.height=edge.maxY-edge.minY;
        var ctx2=canv2.getContext('2d');
        ctx2.putImageData(imgData,0,0);
        var d=canv2.toDataURL("image/png");
        return d;
    } else {return "";}

}