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

var players = {};
var playerSockets = [];
var talon = [];
var asztal = [];
var kezdo = 0;
var kovetkezo = 0;
var tovabbmenok = [];
var order = [];
var numpassz = 0;
var voltlicit = 0;
//var gamenum = 0;

function shuffle(arr) {
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

function checkConnected() {
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
function updatePlist (name, arr){
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
function updateKovetkezo(idx, len){
    if (idx == len - 1){
        return 0;
    }
    else{
        return idx+1;
    }
}

function UltiGame (psocks){
    var finplayers = [];
    var spectators = [];
    var frontwinner;
    var backwinner;
    numpassz = 0;
    tovabbmenok = [];
    voltlicit = 0;
    kezdo = 0;
    var cards = ['M1.png', 'M2.png', 'M3.png', 'M4.png', 'M5.png', 'M6.png', 'M7.png', 'M8.png', 'P1.png', 'P2.png', 'P3.png', 'P4.png', 'P5.png', 'P6.png', 'P7.png', 'P8.png', 'T1.png', 'T2.png', 'T3.png', 'T4.png', 'T5.png', 'T6.png', 'T7.png', 'T8.png', 'Z1.png', 'Z2.png', 'Z3.png', 'Z4.png', 'Z5.png', 'Z6.png', 'Z7.png', 'Z8.png'];
    psocks.forEach(sock => {
        sock.emit('message', "Induljon a jatek");
    })
    var aktdeck = shuffle(cards);
    var cnt= 0;
    psocks.forEach(s => {
        s.emit('elolrol', aktdeck.slice(cnt, cnt+5));
        cnt += 5;
    });
    var leftover = aktdeck.slice(cnt);
    psocks[kezdo].emit('tejossz', voltlicit);
    updatePlist(players[psocks[kezdo].id], Object.values(players));
    //tovabbmenok.push(psocks[kezdo]);
    kezdo++;
    if (kezdo > psocks.length - 1){
        kezdo = 0;
    }
    kovetkezo = kezdo;


    psocks.forEach((player, idx) => {
        // player.on('jatszok', () => {
        //     if (finplayers.length == 2 && leftover.length == 17){
        //         frontwinner = player;
        //         finplayers.push(player);
        //         leftover = shuffle(leftover);
        //         cnt = 0;
        //         finplayers.forEach(s => {
        //             s.emit('hatulrol', leftover.slice(cnt, cnt+5));
        //             cnt += 5;
        //         });
        //         frontwinner.emit('hatulrol', leftover.slice(cnt));
        //         spectators.forEach(s => {
        //             s.emit('nezelod');
        //         });
                // psocks.forEach((player, idx) => {
                //     player.off('jatszok');
                //     player.off('megyek');
                //     player.off('bedobom');
                // });
        //     }
        // });
        // player.on('megyek', () => {
        //     finplayers.push(player);
        //     if (finplayers.length == 2 && leftover.length == 17){
        //         psocks.forEach(s =>{
        //             s.emit('hatulrolmehet');
        //         });
        //     }
        // });
        player.on('bedobom', (arr) => {
            leftover = leftover.concat(arr);
            if (leftover.length == 17){
                leftover = shuffle(leftover);
                var cnt = 0;
                finplayers.forEach(s => {
                    s.emit('hatulrol', leftover.slice(cnt, cnt+5));
                    cnt += 5;
                });
                frontwinner.emit('hatulrol', leftover.slice(cnt));
                order = [];
                finplayers.forEach( s => {
                    order.push(players[s.id]);
                });
                spectators.forEach(s => {
                    s.emit('nezelod', order);
                });
                updatePlist(players[frontwinner.id], Object.values(players));
                kovetkezo = updateKovetkezo(finplayers.indexOf(frontwinner), finplayers.length);
                numpassz = 0;
            }
        });
        player.on('licit', () => {
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
        player.on('kontra', () => {
            if (tovabbmenok.indexOf(player) < 3){
                var tmparr = [tovabbmenok[0], player];
                tovabbmenok.slice(1).forEach(p => { //!!!!!!
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
        player.on('passz', () => {
            numpassz++;
            if (numpassz == psocks.length){
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
            }
            else{
                if (tovabbmenok.length < 3){
                    tovabbmenok.push(player);
                }
                psocks[kovetkezo].emit('tejossz', voltlicit);
                updatePlist(players[psocks[kovetkezo].id], Object.values(players));
                kovetkezo = updateKovetkezo(kovetkezo, psocks.length);
                
            }
        });



        player.on('tospec', (arr) => {
            spectators.forEach(s => {
                s.emit('kezbenlap', {name: players[player.id], lapok: arr});
            });
        });
        player.on('talonbe', (arr) => {
            talon = arr;
            finplayers[kovetkezo].emit('talonvan');
            updatePlist(players[finplayers[kovetkezo].id], Object.values(players));
        });

        player.on('talonki', () => {
            player.emit('hatulrol', talon);
            // finplayers.forEach(s => {
            //     s.emit('talonnincs');
            // });
            kovetkezo = updateKovetkezo(kovetkezo, finplayers.length);
            numpassz = 0;
            backwinner = player;
            //console.log(backwinner);
        });
        player.on('mehet', () => {
            kovetkezo = updateKovetkezo(kovetkezo, finplayers.length);
            numpassz++;
            if (numpassz == 3){
                finplayers.forEach(s => {
                    s.emit('hatulindul', order);
                });
                asztal = [];
                backwinner.emit('tejossz', 0);
                kovetkezo = finplayers.indexOf(backwinner);
            }
            else {
                finplayers[kovetkezo].emit('talonvan');
                updatePlist(players[finplayers[kovetkezo].id], Object.values(players));
            }
        });
        player.on('playcard', (lap) => {
            asztal.push(lap);
            var tmarr = [lap, players[player.id]];
            psocks.forEach(s => {
                s.emit('asztalra', tmarr);
            });
            kovetkezo = updateKovetkezo(kovetkezo, finplayers.length);
            finplayers[kovetkezo].emit('tejossz', 0);
        });
        player.on('viszem', () => {
            psocks.forEach(s =>{
                s.emit('utes', {name: players[player.id], lapok: asztal});
            });
            asztal = [];
            player.emit('tejossz', 0);
            kovetkezo = finplayers.indexOf(player);
        });
        player.on('ujparti', () => {
            finplayers = [];
            spectators = [];
            frontwinner = '';
            numpassz = 0;
            tovabbmenok = [];
            voltlicit = 0;
            aktdeck = shuffle(cards);
            cnt= 0;
            psocks.forEach(s => {
                s.emit('elolrol', aktdeck.slice(cnt, cnt+5));
                cnt += 5;
            });
            leftover = aktdeck.slice(cnt);
            psocks[kezdo].emit('tejossz', voltlicit);
            updatePlist(players[psocks[kezdo].id], Object.values(players));
            //tovabbmenok.push(psocks[kezdo]);
            kezdo++;
            if (kezdo > psocks.length - 1){
                kezdo = 0;
            }
            kovetkezo = kezdo;
        })
    });
}






io.on('connection', (sock) => {
    console.log('Someone connected');
    sock.on('name', (text) => {
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
    //sock.emit('message', 'Hi you are connected');
    sock.on('message', (text) => {
        io.emit('message', text);
    });
    sock.on('start', () => {
        checkConnected();
        //start a game
        UltiGame(playerSockets);
    });
})

server.on('error', (err) => {
    console.error('Server error:', err);
})

server.listen(8000, () => {
    console.log('Ulti started on 8000');
});

// io.attach(server, {
//     pingTimeout: 30000
// });