let userName = null;

var cards = ['M1.png', 'M2.png', 'M3.png', 'M4.png', 'M5.png', 'M6.png', 'M7.png', 'M8.png', 'P1.png', 'P2.png', 'P3.png', 'P4.png', 'P5.png', 'P6.png', 'P7.png', 'P8.png', 'T1.png', 'T2.png', 'T3.png', 'T4.png', 'T5.png', 'T6.png', 'T7.png', 'T8.png', 'Z1.png', 'Z2.png', 'Z3.png', 'Z4.png', 'Z5.png', 'Z6.png', 'Z7.png', 'Z8.png'];

var hand = [];
var state = "elol";
var talon = [];
var clicked = "";
var asztalcnt = 0;
var utesek = {};
var nemjatszik = 0;
var spectator = 0;
var tobbiek = [];
var tobbicnt = 0;
var tobbieklapja = [];
var order = [];
var butt_arr = ["passz", "kontra", "licit"];

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

function clearTable(e){
    cards.forEach(c => {
        var id = c.substring(0,2);
        if (e == "S"){
            hideDiv(id + "S");
            hideDiv(id + "kS");
        }
        if (e == "U"){
            hideDiv(id + "kU");
        }
        if (e == "A"){
            hideDiv(id + "A");
        }
    });
}

function clearTablePart(arr){
    arr.forEach(c => {
        var id = c.substring(0,2);
        hideDiv(id);
    });
}
function playcard(id){
    var oid = id.substring(0,2);
    var tid = oid + ".png";
    if (state == "talonozas"){
        if (hand.includes(tid)) {
            if (hand.length > 10){
                var tmhand = [];
                //clicked = id;
                hand.forEach(c => {
                    if (c != tid){
                        tmhand.push(c);
                    }
                    else{
                        talon.push(c);

                    }
                });
                hand = tmhand;
                clearTable("S");
                clearTable("A");
                showCards(hand);
                showTalon(talon);
            }
        }
        else {
            if (talon.length > 0 && talon.includes(tid)){
                var tmtalon = [];
                //clicked = id;
                talon.forEach(c => {
                    if (c != tid){
                        tmtalon.push(c);
                    }
                    else{
                        hand.push(c);

                    }
                });
                talon = tmtalon;
                clearTable("S");
                clearTable("A");
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
        //clicked = id;
        sock.emit('playcard', oid);
        var tmhand = [];
        hand.forEach(c => {
            if (c != tid){
                tmhand.push(c);
            }
        });
        hand = tmhand;
        sock.emit('tospec', hand);
        clearTable("S");
        showCards(hand);
        state = "lejatszas_varakozik";
    }
}
function showCards (arr){
    arr.sort();
    for (var i = 0; i < arr.length; i++){
        var id = arr[i].substring(0,2);
        var x = document.getElementById(id + "S");
        x.style.left = (20 + i * 70) + "px";
        x.style.zIndex = i;
        x.style.bottom = "15px";
        x.style.display = "block";
    }
}
function showTalon (arr){
    arr.sort();
    for (var j = 0; j < arr.length; j++){
        var id = arr[j].substring(0,2);
        var x = document.getElementById(id + "A");
        x.style.left = (80 + j * 162) + "px";
        x.style.zIndex = j;
        x.style.bottom = "40px";
        x.style.display = "block";
    }
}
function showAsztal (id, num){
    var x = document.getElementById(id + "A");
    if (num == 0){
        x.style.left = "161px";
        x.style.bottom = "5px";
    }
    if (num == 1){
        x.style.left = "282px";
        x.style.bottom = "210px";
    }
    if (num == 2){
        x.style.left = "40px";
        x.style.bottom = "210px";
    }
    x.style.display = "block";
    //clicked = "";
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
function createUtesekDiv (par, num, b, l){
    const dv = document.createElement('div');
    dv.setAttribute("id", "utesek" + num);
    dv.setAttribute("class", "utes-div");
    dv.setAttribute("style", "z-index: 10; display: none; bottom: " + b + "px; left: " + l + "px");
    //const fr = document.createElement('form');
    //fr.setAttribute("id", name + "-form");
    // const bt = document.createElement('button');
    // bt.setAttribute("id", "utesbutton" + num);
    // bt.setAttribute("onmouseover", "showUtesek(this.id)");
    // bt.setAttribute("onmouseout", "hideUtesek(this.id)");
    // dv.appendChild(bt);
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
function reDrawHits(u){
    var cnt1 = 0;
    Object.keys(u).forEach(name => {
        var x = document.getElementById("utesek" + cnt1);
        x.style.display = "block";
        //x = document.getElementById("utesbutton" + cnt1);
        x.innerText = name + " utesei";
        cnt1++;
    });
}
function removeUtesekButt(){
    var arr = [0, 1, 2];
    arr.forEach(num => {
        var x = document.getElementById("utesek" + num);
        x.style.display = "none";
    });
}
function showUtesek(pid){
    //var num = pid.slice(-1);
    var arr = Object.keys(utesek);
    var lapok = utesek[arr[pid]];
    // var utesekcnt = 0;
    var harmas = 0;
    var sor = 0;
    var oszlop = 0;
    var leftside = 3 + pid * 200;
    lapok.forEach(id => {
        var x = document.getElementById(id + "kU");
        x.style.left = (leftside + harmas * 15 + oszlop * 100) + "px";
        x.style.zIndex = harmas + 20;
        x.style.bottom = (315 - harmas * 15 - sor * 82) + "px";
        x.style.display = "block";
        // utesekcnt++;
        harmas++;
        if (harmas == 3){
            oszlop++;
            harmas = 0;
        }
        if (oszlop == 2){
            sor++;
            oszlop = 0;
        }
    });
}
function hideUtesek(pid){
    //var num = pid.slice(-1);
    var arr = Object.keys(utesek);
    var lapok = utesek[arr[pid]];
    //var utesekcnt = 0;
    lapok.forEach(id => {
        var x = document.getElementById(id + "kU");
        x.style.display = "none";
    });
}
function masoklapja(n, l){
    if (!tobbiek.includes(n)){
        tobbiek[tobbicnt] = n;
        tobbieklapja[tobbicnt] = l;
        tobbicnt++;
    }
    clearTable("S");
    tobbiek.forEach((name, idx) => {
        if (name == n){
            l.sort();
            for (var i = l.length-1; i >= 0; i--){
                var id = l[i].substring(0,2);
                var x = document.getElementById(id + "kS");
                x.style.left = (150 + i * 65) + "px";
                x.style.zIndex = i;
                x.style.bottom = ((idx*90) - 35) + "px";
                x.style.display = "block";
            }
            tobbieklapja[idx] = l;
        }
        else {
            var arr = tobbieklapja[idx];
            arr.sort();
            for (var i = arr.length-1; i >= 0; i--){
                var id = arr[i].substring(0,2);
                var x = document.getElementById(id + "kS");
                x.style.left = (150 + i * 65) + "px";
                x.style.zIndex = i;
                x.style.bottom = ((idx*90) - 35) + "px";
                x.style.display = "block";
            }
        }
    });
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
    hideDiv("start-game");
}
// const onBedobom = (e) => {
//     e.preventDefault();
//     sock.emit('bedobom', hand);
//     butt_arr.forEach(x => {
//         hideDiv(x + "-butt");
//     });
//     sock.emit('message', userName + ": bedobta");
//     nemjatszik = 1;
//     spectator = 1;
// }
// const onMegyek = (e) => {
//     e.preventDefault();
//     sock.emit('megyek');
//     butt_arr.forEach(x => {
//         hideDiv(x + "-butt");
//     });
//     sock.emit('message', userName + ": megy tovabb");
//     nemjatszik = 1;
// }
// const onJatszok = (e) => {
//     e.preventDefault();
//     sock.emit('jatszok');
//     butt_arr.forEach(x => {
//         hideDiv(x + "-butt");
//     });
//     sock.emit('message', userName + ": jatszik");
// }
const onLicit = (e) => {
    e.preventDefault();
    sock.emit('licit');
    butt_arr.forEach(x => {
        hideDiv(x + "-butt");
    });
}
const onPassz = (e) => {
    e.preventDefault();
    sock.emit('passz');
    butt_arr.forEach(x => {
        hideDiv(x + "-butt");
    });
}
const onKontra = (e) => {
    e.preventDefault();
    sock.emit('kontra');
    butt_arr.forEach(x => {
        hideDiv(x + "-butt");
    });
}




const onTalon = (e) => {
    e.preventDefault();
    sock.emit('talonbe', talon);
    hideDiv("talonozok-butt");
    clearTable("A");
    talon = [];
    //clicked = '';
}
const onFelvesz = (e) => {
    e.preventDefault();
    sock.emit('talonki');
    hideDiv("felveszem-butt");
    hideDiv("mehet-butt");
}
const onMehet = (e) => {
    e.preventDefault();
    sock.emit('mehet');
    hideDiv("felveszem-butt");
    hideDiv("mehet-butt");
}
// const onLej = (e) => {
//     e.preventDefault();
//     sock.emit('lejatszas');
//     hideDiv("felveszem-butt");
// }
const onVisz = (e) => {
    e.preventDefault();
    sock.emit('viszem');
    state = "lejatszas";
}
const onUjParti = (e) => {
    e.preventDefault();
    sock.emit('ujparti');
}

const parenta = document.querySelector('#asztal-div');
const parentu = document.querySelector('#utesek-div');
const parents = document.querySelector('#sajat-div');
cards.forEach(imageFile => {
    var id = imageFile.substring(0,2);
    // Nagy kartyak legyartasa
    g = document.createElement('div');
    g.setAttribute("id", id + "A");
    g.setAttribute("class", "largecard");
    g.setAttribute("style", "display: none; bottom: 20px");
    g.setAttribute("onclick", "playcard(this.id)");
    p = document.createElement("img");
    p.setAttribute("src", "cards/" + imageFile);
    g.appendChild(p);
    parenta.appendChild(g);
    g = document.createElement('div');
    g.setAttribute("id", id + "S");
    g.setAttribute("class", "largecard");
    g.setAttribute("style", "display: none; bottom: 20px");
    g.setAttribute("onclick", "playcard(this.id)");
    g.setAttribute("onmouseover", "moveCardUp(this)");
    g.setAttribute("onmouseout", "moveCardBack(this)");
    p = document.createElement("img");
    p.setAttribute("src", "cards/" + imageFile);
    g.appendChild(p);
    parents.appendChild(g);
    //Kis kartyak legyartasa
    g = document.createElement('div');
    g.setAttribute("id", id + "kU");
    g.setAttribute("class", "smallcard");
    g.setAttribute("style", "display: none");
    p = document.createElement("img");
    p.setAttribute("src", "cards/" + imageFile);
    p.setAttribute("style", "clip-path: inset(0px 0px 50px 0px);")
    p.setAttribute("width", "64");
    p.setAttribute("height", "100");
    g.appendChild(p);
    parentu.appendChild(g);
    g = document.createElement('div');
    g.setAttribute("id", id + "kS");
    g.setAttribute("class", "smallcard");
    g.setAttribute("style", "display: none");
    p = document.createElement("img");
    p.setAttribute("src", "cards/" + imageFile);
    p.setAttribute("style", "clip-path: inset(0px 0px 50px 0px);")
    p.setAttribute("width", "64");
    p.setAttribute("height", "100");
    g.appendChild(p);
    parents.appendChild(g);
});

var spacer = 0;
butt_arr.forEach(val=> {
    createElolButton(parenta, val, spacer + 100, 200);
    spacer+=60;
});
createElolButton(parenta, "mehet", 100, 200)
createElolButton(parenta, "talonozok", 300, 200);
createElolButton(parenta, "felveszem", 160, 200);
//createElolButton(parent, "lejatszas", 400, 250);
createElolButton(parentu, "ujparti", 5, 500);
createElolButton(parenta, "viszem", 5, 360);
document.querySelector('#start-game').addEventListener('submit', onStartGame);
document.querySelector('#passz-form').addEventListener('submit', onPassz);
document.querySelector('#licit-form').addEventListener('submit', onLicit);
document.querySelector('#kontra-form').addEventListener('submit', onKontra);
document.querySelector('#talonozok-form').addEventListener('submit', onTalon);
document.querySelector('#felveszem-form').addEventListener('submit', onFelvesz);
document.querySelector('#mehet-form').addEventListener('submit', onMehet);
document.querySelector('#viszem-form').addEventListener('submit', onVisz);
document.querySelector('#ujparti-form').addEventListener('submit', onUjParti);
document.querySelector('#chat-form').addEventListener('submit', onFormSubmitted);

createUtesekDiv(parentu, "0", 420, 0);
createUtesekDiv(parentu, "1", 420, 200);
createUtesekDiv(parentu, "2", 420, 400);

// createUteseklButton(parent, "0", 650, 350);
// createUteseklButton(parent, "1", 650, 500);
// createUteseklButton(parent, "2", 650, 650);

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
            hideDiv("start-game");
            clearTable("S");
            clearTable("A");
            clearTable("U");
            hideDiv("ujparti-butt");
            //hideDiv("lejatszas-butt");
            hideDiv("talonozok-butt");
            //hideDiv("utesek0");
            //hideDiv("utesek1");
            //hideDiv("utesek2");
            utesek = {};
            asztalcnt = 0;
            talon = [];
            nemjatszik = 0;
            spectator = 0;
            tobbiek = [];
            tobbieklapja = [];
            tobbicnt = 0;
            order = [];
            // cards.forEach(imageFile => {
            //     var id = imageFile.substring(0,2);
            //     hideDiv(id + "k");
            // });
            //removeUtesekButt();
            state = "elol";
            hand = [];
            hand = hand.concat(subarr);
            showCards(hand);
            // butt_arr.forEach(x => {
            //     showDiv(x + "-butt");
            // });
            // hideDiv("jatszok-butt");
        });
        sock.on('tejossz', (k) => {
            if (state == "elol"){
                showDiv("licit-butt");
                showDiv("passz-butt");
                if (k == 1){
                    showDiv("kontra-butt");
                }
            }
            if (state == "lejatszas_varakozik"){
                state = "lejatszas";
            }
        });
        sock.on('lapotkerek', () => {
            sock.emit('bedobom', hand);
            clearTable("S");
            spectator = 1;
        });
        // sock.on('hatulrolmehet', (arr) => {
            // if (nemjatszik == 0){
            //     hideDiv("bedobom-butt");
            //     hideDiv("megyek-butt");
            //     showDiv("jatszok-butt");
            // }
        // });
        sock.on('hatulrol', (arr) => {
            clearTable("S");
            hand = hand.concat(arr);
            showCards(hand);
            state = "talonozas";
            sock.emit('tospec', hand);
        });
        sock.on('nezelod', (arr) => {
            clearTable("S");
            order = arr;
        });
        sock.on('talonvan', () => {
            showDiv("felveszem-butt");
            showDiv("mehet-butt");
        });
        // sock.on('talonnincs', () => {
        //     hideDiv("felveszem-butt");
        //     hideDiv("lejatszas-butt");
        // });
        sock.on('hatulindul', (arr) => {
            var myidx = arr.indexOf(userName);
            if (myidx == 0){
                order = arr;
            }
            if (myidx == 1){
                order = [userName, arr[2], arr[0]];
            }
            if (myidx == 2){
                order = [userName, arr[0], arr[1]];
            }
            // hideDiv("felveszem-butt");
            // hideDiv("lejatszas-butt");
            state = "lejatszas_varakozik";
            utesek = {};
            showDiv("ujparti-butt");
        });
        sock.on('asztalra', (arr) => {
            showAsztal(arr[0], order.indexOf(arr[1]));
            asztalcnt++;
            if (asztalcnt == 3){
                if (spectator == 0){
                    showDiv("viszem-butt");
                }
                asztalcnt = 0;
            }
        });
        sock.on('utes', (data) => {
            hideDiv("viszem-butt");
            //console.log(data.name);
            //console.log(data.lapok);
            if (!utesek[data.name]){
                utesek[data.name] = data.lapok;
            }
            else{
                utesek[data.name] = utesek[data.name].concat(data.lapok);
            }
            clearTable("A");
            //console.log(utesek);
            reDrawHits(utesek);
            var tmarr = Object.keys(utesek);
            showUtesek(tmarr.indexOf(data.name));
            //state = "lejatszas_varakozik";
            // if (hand.length == 0){
            //     hand = [];
            //     state = "elol";
            //     talon = [];
            //     clicked = "";
            //     asztalcnt = 0;
            //     showDiv("ujparti-butt");
            // }
        });
        sock.on('kezbenlap', (data) => {
            if (spectator == 1){
                masoklapja(data.name, data.lapok);
            }
        });
        sock.emit('name', userName);
    }
};

if (userName == null){
    hideDiv("mainblock");
    document.querySelector('#entry-form').addEventListener('submit', onEntrySubmitted);
}