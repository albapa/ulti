let userName = null;

var cards = ['M1.png', 'M2.png', 'M3.png', 'M4.png', 'M5.png', 'M6.png', 'M7.png', 'M8.png', 'P1.png', 'P2.png', 'P3.png', 'P4.png', 'P5.png', 'P6.png', 'P7.png', 'P8.png', 'T1.png', 'T2.png', 'T3.png', 'T4.png', 'T5.png', 'T6.png', 'T7.png', 'T8.png', 'Z1.png', 'Z2.png', 'Z3.png', 'Z4.png', 'Z5.png', 'Z6.png', 'Z7.png', 'Z8.png'];

var hand = [];
var state = "elol";
var talon = [];
var clicked = "";
var asztalcnt = 0;

function shuffle(arra1) {
    var ctr = arra1.length, temp, index;
    while (ctr > 0) {
        index = Math.floor(Math.random() * ctr);
        ctr--;
        temp = arra1[ctr];
        arra1[ctr] = arra1[index];
        arra1[index] = temp;
    }
    return arra1;
}

function moveCardUp(x){
    var pos = x.style.bottom;
    pos = parseInt(pos.replace("px", "")) + 30;
    x.style.bottom = pos + "px";
}
function moveCardBack(x){
    var pos = x.style.bottom;
    pos = parseInt(pos.replace("px", "")) - 30;
    x.style.bottom = pos + "px";
}

function clearTable(){
    cards.forEach(c => {
        var id = c.substring(0,2);
        hideDiv(id);
    });
}

function clearTablePart(arr){
    arr.forEach(c => {
        var id = c.substring(0,2);
        hideDiv(id);
    });
}
function playcard(id){
    var tid = id + ".png";
    if (state == "talonozas"){
        if (hand.includes(tid)) {
            if (hand.length > 10){
                var tmhand = [];
                clicked = id;
                hand.forEach(c => {
                    if (c != tid){
                        tmhand.push(c);
                    }
                    else{
                        talon.push(c);

                    }
                });
                hand = tmhand;
                clearTable();
                showCards(hand);
                showTalon(talon);
            }
        }
        else {
            if (talon.length > 0 && talon.includes(tid)){
                var tmtalon = [];
                clicked = id;
                talon.forEach(c => {
                    if (c != tid){
                        tmtalon.push(c);
                    }
                    else{
                        hand.push(c);

                    }
                });
                talon = tmtalon;
                clearTable();
                showCards(hand);
                showTalon(talon);
            }
        }
        hideDiv("talonozok-butt");
        if (talon.length == 2){
            showDiv("talonozok-butt");
        }
    }
    if (state == "lejatszas"){
        hideDiv(id);
        clicked = id;
        sock.emit('playcard', id);
        var tmhand = [];
        hand.forEach(c => {
            if (c != tid){
                tmhand.push(c);
            }
        });
        hand = tmhand;
        clearTable();
        showCards(hand);
        state = "lejatszas_varakozik";
    }
}
function showCards (arr){
    arr.sort();
    for (var i = 0; i < arr.length; i++){
        var id = arr[i].substring(0,2);
        var x = document.getElementById(id);
        x.style.left = (20 + i * 60) + "px";
        x.style.zIndex = i;
        x.style.bottom = "20px";
        if (id == clicked){
            x.style.bottom = "50px";
        }
        x.style.display = "block";
    }
}
function showTalon (arr){
    arr.sort();
    for (var j = 0; j < arr.length; j++){
        var id = arr[j].substring(0,2);
        var x = document.getElementById(id);
        x.style.left = (200 + j * 130) + "px";
        x.style.zIndex = j+12;
        x.style.bottom = "300px";
        if (id == clicked){
            x.style.bottom = "330px";
        }
        x.style.display = "block";
    }
}
function showAsztal (id){
    var x = document.getElementById(id);
    x.style.left = (100 + asztalcnt * 130) + "px";
    x.style.zIndex = asztalcnt + 12;
    x.style.bottom = "300px";
    if (id == clicked){
        x.style.bottom = "330px";
    }
    x.style.display = "block";
    clicked = "";
}
function createElolButton (par, name, b, l){
    const dv = document.createElement('div');
    dv.setAttribute("id", name + "-butt");
    dv.setAttribute("class", "elolrol-butt");
    dv.setAttribute("style", "display: none; bottom: " + b + "px; left: " + l + "px");
    const fr = document.createElement('form');
    fr.setAttribute("id", name + "-form");
    const bt = document.createElement('button');
    bt.innerText = name.charAt(0).toUpperCase() + name.slice(1);
    fr.appendChild(bt);
    dv.appendChild(fr);
    par.appendChild(dv);
}
function hideDiv (id){
    var x = document.getElementById(id);
    x.style.display = "none";
}
function showDiv (id){
    var x = document.getElementById(id);
    x.style.display = "block";
}
const sock = io();

const writeEvent = (text) => {
    const parent = document.querySelector('#events');
    const el = document.createElement('li');
    el.innerHTML = text;
    parent.appendChild(el);
    parent.scrollTop = parent.scrollHeight;
};
const writePlayerList = (text) => {
    document.getElementById("player-list").innerHTML = text;
};
const onFormSubmitted = (e) => {
    e.preventDefault();
    const input = document.querySelector('#chat');
    const text = input.value;
    input.value = '';
    sock.emit('message', userName + ": " + text);
}
const onStartGame = (e) => {
    e.preventDefault();
    sock.emit('start');
}
const onBedobom = (e) => {
    e.preventDefault();
    sock.emit('bedobom', hand);
    butt_arr.forEach(x => {
        hideDiv(x + "-butt");
    });
    sock.emit('message', userName + ": bedobta");
}
const onMegyek = (e) => {
    e.preventDefault();
    sock.emit('megyek');
    butt_arr.forEach(x => {
        hideDiv(x + "-butt");
    });
    sock.emit('message', userName + ": megy tovabb");
}
const onJatszok = (e) => {
    e.preventDefault();
    sock.emit('jatszok');
    butt_arr.forEach(x => {
        hideDiv(x + "-butt");
    });
    sock.emit('message', userName + ": jatszik");
}
const onTalon = (e) => {
    e.preventDefault();
    sock.emit('talonbe', talon);
    hideDiv("talonozok-butt");
    clearTablePart(talon);
    talon = [];
    clicked = '';
}
const onFelvesz = (e) => {
    e.preventDefault();
    sock.emit('talonki');
    hideDiv("felveszem-butt");
}
const onLej = (e) => {
    e.preventDefault();
    sock.emit('lejatszas');
    hideDiv("felveszem-butt");
}

const parent = document.querySelector('#gameplace');
cards.forEach(imageFile => {
    var id = imageFile.substring(0,2);
    const g = document.createElement('div');
    g.setAttribute("id", id);
    g.setAttribute("class", "largecard");
    g.setAttribute("style", "display: none; bottom: 20px");
    g.setAttribute("onclick", "playcard(this.id)");
    g.setAttribute("onmouseover", "moveCardUp(this)");
    g.setAttribute("onmouseout", "moveCardBack(this)");
    p = document.createElement("img");
    p.setAttribute("src", "cards/" + imageFile);
    g.appendChild(p);
    parent.appendChild(g);
});
var butt_arr = ["bedobom", "megyek", "jatszok"];
var spacer = 0;
butt_arr.forEach(val=> {
    createElolButton(parent, val, 300, spacer + 100);
    spacer+=120;
})
createElolButton(parent, "talonozok", 400, 500);
createElolButton(parent, "felveszem", 400, 500);
createElolButton(parent, "lejatszas", 400, 250);
document.querySelector('#start-game').addEventListener('submit', onStartGame);
document.querySelector('#bedobom-form').addEventListener('submit', onBedobom);
document.querySelector('#megyek-form').addEventListener('submit', onMegyek);
document.querySelector('#jatszok-form').addEventListener('submit', onJatszok);
document.querySelector('#talonozok-form').addEventListener('submit', onTalon);
document.querySelector('#felveszem-form').addEventListener('submit', onFelvesz);
document.querySelector('#lejatszas-form').addEventListener('submit', onLej);
document.querySelector('#chat-form').addEventListener('submit', onFormSubmitted);

const onEntrySubmitted = (e) => {
    e.preventDefault();
    const input = document.querySelector('#name');
    userName = input.value;
    if (userName){
        hideDiv("entry");
        var x = document.getElementById("mainblock");
        x.style.display = "flex";
        hideDiv("start-game");
        writeEvent('Otlapos Ulti beszelgetes');
        sock.on('message', (text) => {
            writeEvent(text);
        });
        sock.on('plist', (text) => {
            writePlayerList("Belepett jatekosok:<br/>" + text);
        });
        sock.on('canstart', () => {
            showDiv("start-game");
        });
        sock.on('elolrol', (subarr)=>{
            clearTable();
            state = "elol";
            hand = [];
            hand = hand.concat(subarr);
            showCards(hand);
            butt_arr.forEach(x => {
                showDiv(x + "-butt");
            });
        });
        sock.on('hatulrol', (arr) => {
            clearTable();
            hand = hand.concat(arr);
            showCards(hand);
            state = "talonozas";
            sock.emit('tospec', hand);
        });
        sock.on('nezelod', () => {
            clearTable();
        });
        sock.on('talonvan', () => {
            showDiv("felveszem-butt");
            showDiv("lejatszas-butt");
        });
        sock.on('hatulindul', () => {
            hideDiv("felveszem-butt");
            hideDiv("lejatszas-butt");
            state = "lejatszas";
        });
        sock.on('asztalra', (lap) => {
            showAsztal(lap);
            asztalcnt++;
        })
        sock.emit('name', userName);
    }
};

if (userName == null){
    hideDiv("mainblock");
    document.querySelector('#entry-form').addEventListener('submit', onEntrySubmitted);
}