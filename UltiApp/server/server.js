const http = require('http');
const express = require('express');
const socketio = require('socket.io');
//const UltiGame = require('./ulti-game');

const app = express();

const clientPath = `${__dirname}/../client`;
console.log(`Serving static from ${clientPath}`);

app.use(express.static(clientPath));

const server = http.createServer(app);
const io = socketio(server);

var players = {}; // objektum valtozo a nevek es socket id-ktarolasara
var playerSockets = []; // array a teljes socket-ek tarolasara
var talon = []; // talon tarolo array
var asztal = []; // asztalra kijatszott lapokat tarolo array
var kezdo = 0; // Ez a valtozo adja meg, hogy ki kezdi a jatekot
var kovetkezo = 0; // Ez koveti, hogy a ki a kovetkezo jatekon belul
var tovabbmenok = []; // Ez az array fogja gyujteni a liciteket / kontrakat elolrol
var order = []; // A jatekosok sorrendje hatulrol lejatszasnal
var numpassz = 0; // Ez gyujti, hogy hanyan passzoltak
var voltlicit = 0; // magaert beszel, a kontra miatt van itt
var teritett = 0; //teritett jatek kapcsolo
var teritopl = '';

function shuffle(arr) { // kartya kevero funkcio
    var ctr = arr.length, temp, index;
    while (ctr > 0) {
        index = Math.floor(Math.random() * ctr);
        ctr--;
        temp = arr[ctr];
        arr[ctr] = arr[index];
        arr[index] = temp;
    }
    return arr;
}

function checkConnected() { // Funkcio a csatlakozott jatekosok ellenorzesere
    var tmplayers = {};
    var tmplayersock = [];
    Object.keys(players).forEach(id => {
        if (io.sockets.connected[id]) { 
            tmplayers[id] = players[id];
            playerSockets.forEach(s => {
                if (s.id == id){
                    tmplayersock.push(s);
                }
            });
            
        }
    });
    players = tmplayers;
    playerSockets = tmplayersock;
    io.emit('plist', Object.values(players).join("<br/>"));
}

function updatePlist (name, arr){ // Ez a funkcio frissiti es kuldi ki a jatekosoknak a nev listat,ha kell akkor jelezve, hogy ki jon
    var tmparr = [];
    arr.forEach(n => {
        if (n == name){
            tmparr.push("> " + n);
        }
        else{
            tmparr.push(n);
        }
    });
    io.emit('plist', tmparr.join("<br/>"));
}
function updateKovetkezo(idx, len){ // Ki a kovetkezo funkcio, ha a lista vegere er, akkor menjen az elejere
    if (idx == len - 1){
        return 0;
    }
    else{
        return idx+1;
    }
}

function UltiGame (psocks){ // Ez a jatek motorja
    var finplayers = []; // Ez az array fogja tartalmazni a hatulrol jatszok socket-jet
    var spectators = []; // Ez meg azokat akik nem jatszanak de nezik a jatekot
    var frontwinner; // Aki megnyeri a licitet elolrol
    var backwinner; // Es aki hatulrol
    numpassz = 0;
    tovabbmenok = [];
    voltlicit = 0;
    kezdo = 0;
    teritett = 0;
    teritopl = '';
    var cards = ['M1.png', 'M2.png', 'M3.png', 'M4.png', 'M5.png', 'M6.png', 'M7.png', 'M8.png', 'P1.png', 'P2.png', 'P3.png', 'P4.png', 'P5.png', 'P6.png', 'P7.png', 'P8.png', 'T1.png', 'T2.png', 'T3.png', 'T4.png', 'T5.png', 'T6.png', 'T7.png', 'T8.png', 'Z1.png', 'Z2.png', 'Z3.png', 'Z4.png', 'Z5.png', 'Z6.png', 'Z7.png', 'Z8.png'];
    psocks.forEach(sock => { // Csak egy kis batoritas
        sock.emit('message', "Induljon a jatek");
    })
    var aktdeck = shuffle(cards);
    var cnt= 0;
    psocks.forEach(s => { // elolrol osztas mindenkinek 5 lap
        s.emit('elolrol', aktdeck.slice(cnt, cnt+5));
        cnt += 5;
    });
    var leftover = aktdeck.slice(cnt); // Ez a valtozo tartalmazza mindig a maradek kartyakat
    psocks[kezdo].emit('tejossz', voltlicit); // uzenet a kezdo jatekosnak (ezzel kerulnek majd ki a licit es passz gombok)
    updatePlist(players[psocks[kezdo].id], Object.values(players));
    kezdo++; // Ettol kezdi majd a kovetkezo partit a kovetkezo jatekos
    if (kezdo > psocks.length - 1){
        kezdo = 0;
    }
    kovetkezo = kezdo;
    psocks.forEach((player, idx) => { // Ezeket a socket listenereket fogja minden jatekos fele megnyitni
        player.on('bedobom', (arr) => { // amikor az elolrol kimaradok bedobjak a lapjukat
            leftover = leftover.concat(arr);
            if (leftover.length == 17){
                leftover = shuffle(leftover);
                var cnt = 0;
                finplayers.forEach(s => { // hatso 5 lap kiosztasa
                    s.emit('hatulrol', leftover.slice(cnt, cnt+5));
                    cnt += 5;
                });
                frontwinner.emit('hatulrol', leftover.slice(cnt)); // maradek ketto kiosztasa
                order = [];
                finplayers.forEach( s => { // mindenkinek kikuldi a sorrendet
                    order.push(players[s.id]);
                });
                spectators.forEach(s => { // megmondja, hogy ki lesz nezelodo
                    s.emit('nezelod', order);
                });
                updatePlist(players[frontwinner.id], Object.values(players));
                kovetkezo = updateKovetkezo(finplayers.indexOf(frontwinner), finplayers.length);
                numpassz = 0;
            }
        });
        player.on('licit', () => { // amikor valaki elolrol licital
            if (tovabbmenok.indexOf(player) < 3){
                var tmparr = [player];
                tovabbmenok.forEach(p => {
                    if (p != player){
                        tmparr.push(p);
                    }
                });
                tovabbmenok = tmparr;
            }
            else {
                tovabbmenok.unshift(player);
            }
            voltlicit = 1;
            psocks[kovetkezo].emit('tejossz', voltlicit);
            updatePlist(players[psocks[kovetkezo].id], Object.values(players));
            kovetkezo = updateKovetkezo(kovetkezo, psocks.length);
            numpassz = 0;
        });
        player.on('kontra', () => { // amikor valaki elolrol kontrazik
            if (tovabbmenok.indexOf(player) < 3){
                var tmparr = [tovabbmenok[0], player];
                tovabbmenok.slice(1).forEach(p => {
                    if (p != player){
                        tmparr.push(p);
                    }
                });
            }
            else {
                var tmparr = [tovabbmenok[0], player, tovabbmenok.slice(1)];
            }
            tovabbmenok = tmparr;
            voltlicit = 0;
            psocks[kovetkezo].emit('tejossz', voltlicit);
            updatePlist(players[psocks[kovetkezo].id], Object.values(players));
            kovetkezo = updateKovetkezo(kovetkezo, psocks.length);
            numpassz = 0;
        });
        player.on('passz', () => { // amikor valaki elolrol passzol
            numpassz++;
            if (numpassz == psocks.length){ // ha mar mindenki passzolt
                finplayers = tovabbmenok.slice(0,3);
                frontwinner = finplayers[0];
                backwinner = frontwinner;
                spectators = [];
                var tmarr = [];
                psocks.forEach(s => {
                    if (!finplayers.includes(s)){
                        spectators.push(s);
                        s.emit('lapotkerek');
                    }
                    else {
                        tmarr.push(s);
                    }
                });
                finplayers = tmarr;
                if (psocks.length == 3){ //ha csak harman jatszanak es nincs aki bedobja
                    frontwinner.emit('jelezzvissza');
                }
            }
            else{
                if (tovabbmenok.length < 3){
                    tovabbmenok.push(player);
                }
                if (psocks[kovetkezo] != tovabbmenok[0]){
                    psocks[kovetkezo].emit('tejossz', voltlicit);
                }
                else{
                    psocks[kovetkezo].emit('tejossz', 0);
                }
                updatePlist(players[psocks[kovetkezo].id], Object.values(players));
                kovetkezo = updateKovetkezo(kovetkezo, psocks.length);
                
            }
        });



        player.on('tospec', (arr) => { // ez a socket fogadja a lapokat a hatulrol jatszok kezebol es tovabbitja a nezelodo jatekosoknak
            spectators.forEach(s => {
                s.emit('kezbenlap', {name: players[player.id], lapok: arr});
            });
            if (teritett == 1 && teritopl == player){
                finplayers.forEach(p => {
                    p.emit('teritett', arr);
                });
            }
        });
        player.on('tospect', (arr) => { // ez a socket fogadja a lapokat a hatulrol jatszok kezebol es tovabbitja a nezelodo jatekosoknak
            spectators.forEach(s => {
                s.emit('kezbenlapt', arr);
            });
        });
        player.on('talonbe', (arr) => { // mikor valaki lerakja a talont
            talon = arr;
            finplayers[kovetkezo].emit('talonvan');
            updatePlist(players[finplayers[kovetkezo].id], Object.values(players));
        });

        player.on('talonki', () => { // mikor valaki felveszi a talont
            player.emit('hatulrol', talon);
            kovetkezo = updateKovetkezo(kovetkezo, finplayers.length);
            numpassz = 0;
            backwinner = player;
        });
        player.on('mehet', () => { // mikor hatulrol passzolsz
            kovetkezo = updateKovetkezo(kovetkezo, finplayers.length);
            numpassz++;
            if (numpassz == 3){
                finplayers.forEach(s => {
                    s.emit('hatulindul', order);
                });
                asztal = [];
                backwinner.emit('tejossz', 0);
                backwinner.emit('kezbenlapt', talon);
                kovetkezo = finplayers.indexOf(backwinner);
            }
            else {
                finplayers[kovetkezo].emit('talonvan');
                updatePlist(players[finplayers[kovetkezo].id], Object.values(players));
            }
        });
        player.on('playcard', (lap) => { // kartya kijatszasa barhonnan
            asztal.push(lap);
            var tmarr = [lap, players[player.id]];
            psocks.forEach(s => {
                s.emit('asztalra', tmarr);
            });
            kovetkezo = updateKovetkezo(kovetkezo, finplayers.length);
            finplayers[kovetkezo].emit('tejossz', 0);
        });
        player.on('viszem', () => { // ha valaki viszi az utest
            psocks.forEach(s =>{
                s.emit('utes', {name: players[player.id], lapok: asztal});
            });
            asztal = [];
            player.emit('tejossz', 0);
            kovetkezo = finplayers.indexOf(player);
        });
        player.on('ujparti', () => { // ujparti inditas, valtozok kiuritese, nullazasa, uj keveres, stb
            finplayers = [];
            spectators = [];
            frontwinner = '';
            numpassz = 0;
            tovabbmenok = [];
            voltlicit = 0;
            teritett = 0;
            aktdeck = shuffle(cards);
            cnt= 0;
            teritopl = '';
            psocks.forEach(s => {
                s.emit('elolrol', aktdeck.slice(cnt, cnt+5));
                cnt += 5;
            });
            leftover = aktdeck.slice(cnt);
            psocks[kezdo].emit('tejossz', voltlicit);
            updatePlist(players[psocks[kezdo].id], Object.values(players));
            kezdo++;
            if (kezdo > psocks.length - 1){
                kezdo = 0;
            }
            kovetkezo = kezdo;
        });
        player.on('teritek', (arr) => {
            teritett = 1;
            teritopl = player;
            finplayers.forEach(p => {
                p.emit('teritett', arr);
            });
        });
    });
}


io.on('connection', (sock) => {
    console.log('Someone connected');
    sock.on('name', (text) => { // Ez a socket listener veszi be a jatekosok nevet es figyeli, hogy van-e mar harom jatekos
        players[sock.id] = text;
        playerSockets.push(sock);
        console.log('Belepett ' + text + ' ID: ' + sock.id);
        checkConnected();
        if (Object.keys(players).length > 2){
            io.emit('message', 'Indulhat a jatek');
            io.emit('canstart');
        }
        else{
            io.emit('message', 'Varunk mig legalabb harman leszunk...');
        }
    });
    sock.on('message', (text) => { // Ez a socket listener kezeli a bal oldali csetbe jovo uzenetek tovabbitasat
        io.emit('message', text);
    });
    sock.on('start', () => { // Jatek inditasa gombra indul a fo funkcio
        checkConnected();
        UltiGame(playerSockets);
    });
})

server.on('error', (err) => { // Csak egy kis error log funkcio
    console.error('Server error:', err);
})

server.listen(8000, () => { // Itt mondod meg, hogy melyik porton hallgasson a szerver
    console.log('Ulti started on 8000');
});
