let userName = null;

var cards = ['M1.png', 'M2.png', 'M3.png', 'M4.png', 'M5.png', 'M6.png', 'M7.png', 'M8.png', 'P1.png', 'P2.png', 'P3.png', 'P4.png', 'P5.png', 'P6.png', 'P7.png', 'P8.png', 'T1.png', 'T2.png', 'T3.png', 'T4.png', 'T5.png', 'T6.png', 'T7.png', 'T8.png', 'Z1.png', 'Z2.png', 'Z3.png', 'Z4.png', 'Z5.png', 'Z6.png', 'Z7.png', 'Z8.png'];

var hand = []; // array a kezben levo lapokra
var state = "elol"; // jatek fazis jelzo valtozo
var talon = []; // array a talonnak
var asztalcnt = 0; // hany lap van az asztalon
var utesek = {}; // ez az objektum fogja gyujteni az uteseket
var spectator = 0; // valtozo ha csak nezelodsz
var tobbiek = []; // ezek a valtozok kellenek annak aki nezelodik a tobbiek kovetesere
var tobbicnt = 0;
var tobbieklapja = [];
var order = []; // a lejatszok sorrendje
var butt_arr = ["passz", "kontra", "licit"]; // elolrol gombok


function moveCardUp(x){ // funkcio a kartya onmouseover effect-jehez
    var pos = x.style.bottom;
    pos = parseInt(pos.replace("px", "")) + 30;
    x.style.bottom = pos + "px";
}
function moveCardBack(x){ // ez meg, hogy a kartya visszakeruljon ha mar nincs folotte az eger
    var pos = x.style.bottom;
    pos = parseInt(pos.replace("px", "")) - 30;
    x.style.bottom = pos + "px";
}

function clearTable(e){ // jatekter tisztito funkcio S: sajat lapok (also resz), U: utesek resz (jobb felso), A: asztal, ahova a kartyak vannak kijatszva
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

function playcard(id){ // kartya kijatszas funkcioja, fuggoen attol, hogy eppen talonozas vagy lejatszas van
    var oid = id.substring(0,2);
    var tid = oid + ".png";
    if (state == "talonozas"){
        if (hand.includes(tid)) {
            if (hand.length > 10){
                var tmhand = [];
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
function showCards (arr){ // Ez a funkcio rajzolja ki a kezben levo lapokat
    //arr.sort();
    arr = customSort(arr);
    for (var i = 0; i < arr.length; i++){
        var id = arr[i].substring(0,2);
        var x = document.getElementById(id + "S");
        x.style.left = (20 + i * 70) + "px";
        x.style.zIndex = i;
        x.style.bottom = "15px";
        x.style.display = "block";
    }
}
function showTalon (arr){ // Ez helyezi az asztalra a talonozott lapokat
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
function showAsztal (id, num){ // Ez helyezi az asztalra a lapokat a lejatszasnal
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
}
function createElolButton (par, name, b, l){ // gombkeszito funkcio (nem hasznalhato ingekhez)
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
function createUtesekDiv (par, num, b, l){ // utesek fejlecet (az ures szovegmezok) keszito funkcio
    const dv = document.createElement('div');
    dv.setAttribute("id", "utesek" + num);
    if (num.substring(0,1) == "m"){
        dv.setAttribute("class", "maslapok-div");
    }
    else{
        dv.setAttribute("class", "utes-div");
    }
    dv.setAttribute("style", "z-index: 10; display: none; bottom: " + b + "px; left: " + l + "px");
    par.appendChild(dv);
}
function hideDiv (id){ // div elem eltunteto id alapja
    var x = document.getElementById(id);
    x.style.display = "none";
}
function showDiv (id){ // div elem megjelenito id alapjan
    var x = document.getElementById(id);
    x.style.display = "block";
}
function reDrawHits(u){ // Utesek fejlecet szoveggel feltolto funkcio
    var cnt1 = 0;
    Object.keys(u).forEach(name => {
        var x = document.getElementById("utesek" + cnt1);
        x.style.display = "block";
        x.innerText = name + " utesei";
        cnt1++;
    });
}
function showUtesek(pid){ // Ez rajzolja ki az uteseket jobb oldalra
    var arr = Object.keys(utesek);
    var lapok = utesek[arr[pid]];
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
function masoklapja(n, l){ // Ez a funkcio rajzolja ki a lejatszok lapjat a nezelodo(k)nek
    if (!tobbiek.includes(n)){
        tobbiek[tobbicnt] = n;
        tobbieklapja[tobbicnt] = l;
        tobbicnt++;
    }
    clearTable("S");
    tobbiek.forEach((name, idx) => {
        if (name == n){
            l = customSort(l);
            for (var i = l.length-1; i >= 0; i--){
                var id = l[i].substring(0,2);
                var x = document.getElementById(id + "kS");
                x.style.left = (150 + i * 65) + "px";
                x.style.zIndex = i;
                x.style.bottom = ((idx*90) - 35) + "px";
                x.style.display = "block";
                x = document.getElementById("utesekm" + idx);
                x.style.display = "block";
                x.innerText = name + ":";
            }
            tobbieklapja[idx] = l;
        }
        else {
            var arr = tobbieklapja[idx];
            arr = customSort(arr);
            for (var i = arr.length-1; i >= 0; i--){
                var id = arr[i].substring(0,2);
                var x = document.getElementById(id + "kS");
                x.style.left = (150 + i * 65) + "px";
                x.style.zIndex = i;
                x.style.bottom = ((idx*90) - 35) + "px";
                x.style.display = "block";
                x = document.getElementById("utesekm" + idx);
                x.style.display = "block";
                x.innerText = name + ":";
            }
        }
    });
}
function masoklapjatal (arr) {
    var id = arr[0].substring(0,2);
    var x = document.getElementById(id + "kS");
    x.style.left = "980px";
    x.style.zIndex = 1;
    x.style.bottom = "15px";
    x.style.display = "block";
    id = arr[1].substring(0,2);
    var x = document.getElementById(id + "kS");
    x.style.left = "980px";
    x.style.zIndex = 2;
    x.style.bottom = "95px";
    x.style.display = "block";
}
function customSort (arr) { // kartyak sorba rendezese Zoli kerese alapjan
    var szinarr = ["T", "Z", "M", "P"];
    var tmo = {};
    szinarr.forEach(szin => {
        tmo[szin] = [];
    });
    arr.forEach(lap => {
        tmo[lap.substring(0,1)].push(lap);
    });
    var tmarr = [];
    szinarr.forEach(szin => {
        tmo[szin].sort();
        tmarr = tmarr.concat(tmo[szin]);
    });
    return tmarr;
}
function showTer (arr) { // ez mutattja a terito jatekos lapjait
    hideDiv('teritek-butt');
    arr = customSort(arr);
    var i = 0;
    arr.forEach(lap => {
        var id = lap.substring(0,2);
        var x = document.getElementById(id + "kU");
        x.style.left = (2 + i * 50) + "px";
        x.style.zIndex = i+20;
        x.style.bottom = "-50px";
        x.style.display = "block";
        i++;
    });
}


const sock = io(); // Inicialja a kapcsolatot a szerverrel

const writeEvent = (text) => { // ez kezeli a cset ablakba beirt szovegeket
    const parent = document.querySelector('#events');
    const el = document.createElement('li');
    el.innerHTML = text;
    parent.appendChild(el);
    parent.scrollTop = parent.scrollHeight;
};
const writePlayerList = (text) => { // ez frissiti a jatekosok listajat
    document.getElementById("player-list").innerHTML = text;
};
const onFormSubmitted = (e) => { // ez kuldi a cset szoveget
    e.preventDefault();
    const input = document.querySelector('#chat');
    const text = input.value;
    input.value = '';
    sock.emit('message', userName + ": " + text);
}
const onStartGame = (e) => { // Jatek indito gomb (ez csak a legelejen)
    e.preventDefault();
    sock.emit('ujparti');
    hideDiv("start-game");
}
const onLicit = (e) => { // licit gomb teendo
    e.preventDefault();
    sock.emit('elovalasztas', 'licit');
    butt_arr.forEach(x => {
        hideDiv(x + "-butt");
    });
}
const onPassz = (e) => { // passz gom teendo
    e.preventDefault();
    sock.emit('elovalasztas', 'passz');
    butt_arr.forEach(x => {
        hideDiv(x + "-butt");
    });
}
const onKontra = (e) => { // kontra gomb teendo
    e.preventDefault();
    sock.emit('elovalasztas', 'kontra');
    butt_arr.forEach(x => {
        hideDiv(x + "-butt");
    });
}
const onTalon = (e) => { // talonozas gomb teendo
    e.preventDefault();
    sock.emit('talonbe', talon);
    hideDiv("talonozok-butt");
    clearTable("A");
    sock.emit('tospec', hand);
    sock.emit('tospect', talon);
    talon = [];
}
const onFelvesz = (e) => { // talon felvevo gomb teendo
    e.preventDefault();
    sock.emit('talonki');
    hideDiv("felveszem-butt");
    hideDiv("mehet-butt");
}
const onMehet = (e) => { // hatulrol passz (mehet) gomb teendo
    e.preventDefault();
    sock.emit('mehet');
    hideDiv("felveszem-butt");
    hideDiv("mehet-butt");
}
const onVisz = (e) => { // viszem gomb teendo
    e.preventDefault();
    sock.emit('viszem');
    state = "lejatszas";
}
const onUjParti = (e) => { // uj parti gomb teendo
    e.preventDefault();
    sock.emit('ujparti');
}
const onTerit = (e) => { // uj parti gomb teendo
    e.preventDefault();
    sock.emit('teritek', hand);
    hideDiv('teritek-butt');
}

// ez a harom definialja a parent-eket a div-ek szamara a/u/s
const parenta = document.querySelector('#asztal-div');
const parentu = document.querySelector('#utesek-div');
const parents = document.querySelector('#sajat-div');
cards.forEach(imageFile => {
    var id = imageFile.substring(0,2);
    // Nagy kartyak legyartasa es helyukre rakasa (rejtve)
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
    //Kis kartyak legyartasa es helyukre rakasa (rejtve)
    g = document.createElement('div');
    g.setAttribute("id", id + "kU");
    g.setAttribute("class", "smallcard");
    g.setAttribute("style", "display: none");
    p = document.createElement("img");
    p.setAttribute("src", "cards/" + imageFile);
    p.setAttribute("style", "clip-path: inset(0px 0px 50px 0px);"); // itt vagom le a kartya felet
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

// Itt jon a sok-sok gomb legyartasa es a listener-ek rarakasa
var spacer = 0;
butt_arr.forEach(val=> {
    createElolButton(parenta, val, spacer + 100, 200);
    spacer+=60;
});
createElolButton(parenta, "mehet", 100, 200)
createElolButton(parenta, "talonozok", 300, 200);
createElolButton(parenta, "felveszem", 160, 200);
createElolButton(parentu, "ujparti", 5, 515);
createElolButton(parentu, "teritek", 5, 450);
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
document.querySelector('#teritek-form').addEventListener('submit', onTerit);
document.querySelector('#chat-form').addEventListener('submit', onFormSubmitted);

createUtesekDiv(parentu, "0", 422, 10);
createUtesekDiv(parentu, "1", 422, 210);
createUtesekDiv(parentu, "2", 422, 410);
createUtesekDiv(parents, "m0", 35, 5);
createUtesekDiv(parents, "m1", 125, 5);
createUtesekDiv(parents, "m2", 215, 5);
createUtesekDiv(parenta, "n1", 422, 256);
createUtesekDiv(parenta, "n2", 422, 14);

const onEntrySubmitted = (e) => { // ha belepsz a neveddel
    e.preventDefault();
    const input = document.querySelector('#name');
    userName = input.value;
    if (userName){
        hideDiv("entry");
        var x = document.getElementById("mainblock");
        x.style.display = "flex";
        hideDiv("start-game");
        writeEvent('Otlapos Ulti beszelgetes');
        sock.on('message', (text) => { // ez hallgat a bejovo cset uzenetekre
            writeEvent(text);
        });
        sock.on('plist', (text) => { // ez hallgat a bejovo player listara
            writePlayerList("Belepett jatekosok:<br/>" + text);
        });
        sock.on('canstart', () => { // ez hallgat arra, ha van mar harom jatekos es indulhat a jatek
            showDiv("start-game");
        });
        sock.on('elolrol', (subarr)=>{ // ez fogadja az elolrol osztast
            hideDiv("start-game");
            clearTable("S");
            clearTable("A");
            clearTable("U");
            hideDiv("ujparti-butt");
            hideDiv("teritek-butt");
            hideDiv("talonozok-butt");
            hideDiv("viszem-butt");
            hideDiv("utesek0");
            hideDiv("utesek1");
            hideDiv("utesek2");
            hideDiv("utesekm0");
            hideDiv("utesekm1");
            hideDiv("utesekm2");
            hideDiv("utesekn1");
            hideDiv("utesekn2");
            utesek = {};
            asztalcnt = 0;
            talon = [];
            spectator = 0;
            tobbiek = [];
            tobbieklapja = [];
            tobbicnt = 0;
            order = [];
            state = "elol";
            hand = [];
            hand = hand.concat(subarr);
            showCards(hand);
        });
        sock.on('tejossz', (k) => { //ez fogadja az ertesitest ha a jatekos jon
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
        sock.on('lapotkerek', () => { // ez jon annak aki kimarad, hogy bedobja a lapjat
            sock.emit('bedobom', hand);
            clearTable("S");
            spectator = 1;
        });
        sock.on('jelezzvissza', () => { // egy dummy bedobas ha harman jatszanak es nincs senki aki bedobja
            var tmarr = [];
            sock.emit('bedobom', tmarr);
        });
        sock.on('hatulrol', (arr) => { // hatulrol megkapott lapok
            clearTable("S");
            hand = hand.concat(arr);
            showCards(hand);
            state = "talonozas";
            sock.emit('tospec', hand);
        });
        sock.on('nezelod', (arr) => { // ertesites, hogy nem jatszol de nezelodsz
            clearTable("S");
            order = arr;
        });
        sock.on('talonvan', () => { // ertesites ha talon van
            showDiv("felveszem-butt");
            showDiv("mehet-butt");
        });
        sock.on('hatulindul', (arr) => { // indul a lejatszas hatul
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
            var x = document.getElementById("utesekn1");
            x.style.display = "block";
            x.innerText = order[1];
            x = document.getElementById("utesekn2");
            x.style.display = "block";
            x.innerText = order[2];
            state = "lejatszas_varakozik";
            utesek = {};
            showDiv("ujparti-butt");
            showDiv("teritek-butt");
        });
        sock.on('asztalra', (arr) => { //erre jonnek a lapok az asztalra
            showAsztal(arr[0], order.indexOf(arr[1]));
            asztalcnt++;
            if (asztalcnt == 3){
                if (spectator == 0){
                    showDiv("viszem-butt");
                }
                asztalcnt = 0;
            }
        });
        sock.on('utes', (data) => { // erre jonnek az utesek, hogy ki lehessen rakni
            hideDiv("viszem-butt");
            if (!utesek[data.name]){
                utesek[data.name] = data.lapok;
            }
            else{
                utesek[data.name] = utesek[data.name].concat(data.lapok);
            }
            clearTable("A");
            reDrawHits(utesek);
            var tmarr = Object.keys(utesek);
            showUtesek(tmarr.indexOf(data.name));
        });
        sock.on('kezbenlap', (data) => { // erre jonnek masok lapjai a nezelodoknek
            if (spectator == 1){
                masoklapja(data.name, data.lapok);
            }
        });
        sock.on('kezbenlapt', (arr) => { // erre jonnek masok lapjai a nezelodoknek
            //if (spectator == 1){
                masoklapjatal(arr);
            //}
        });
        sock.on('teritett', (arr) => {
            showTer(arr);
        });
        sock.emit('name', userName);
    }
};

if (userName == null){ // ez van ha meg nem leptel be
    hideDiv("mainblock");
    document.querySelector('#entry-form').addEventListener('submit', onEntrySubmitted);
}