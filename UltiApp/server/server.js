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

var players = [];
var playerIds = [];
var playerSockets = [];

let waitingPlayer = null;

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

function UltiGame (ps, pids, psocks){
    var finplayers = [];
    var finplayerindexes = [];
    var spectators = [];
    var frontwinner;
    var cards = ['M1.png', 'M2.png', 'M3.png', 'M4.png', 'M5.png', 'M6.png', 'M7.png', 'M8.png', 'P1.png', 'P2.png', 'P3.png', 'P4.png', 'P5.png', 'P6.png', 'P7.png', 'P8.png', 'T1.png', 'T2.png', 'T3.png', 'T4.png', 'T5.png', 'T6.png', 'T7.png', 'T8.png', 'Z1.png', 'Z2.png', 'Z3.png', 'Z4.png', 'Z5.png', 'Z6.png', 'Z7.png', 'Z8.png'];
    psocks.forEach(sock => {
        sock.emit('message', "Induljon a jatek");
    })
    var aktdeck = shuffle(cards);
    //var pass1 = 0;
    var cnt= 0;
    psocks.forEach(s => {
        s.emit('elolrol', aktdeck.slice(cnt, cnt+5));
        cnt += 5;
    });
    var leftover = aktdeck.slice(cnt);

    psocks.forEach((player, idx) => {
        //console.log(player.eventNames);
        player.on('jatszok', () => {
            if (finplayers.length == 2 && leftover.length == 17){
                //console.log("haho");
                frontwinner = player;
                finplayers.push(player);
                finplayerindexes.push(idx);
                leftover = shuffle(leftover);
                cnt = 0;
                finplayers.forEach(s => {
                    s.emit('hatulrol', leftover.slice(cnt, cnt+5));
                    //console.log("Emitted to " + s.id);
                    cnt += 5;
                });
                frontwinner.emit('hatulrol', leftover.slice(cnt));
                spectators.forEach(s => {
                    s.emit('nezelod');
                });
                // psocks.forEach((player, idx) => {
                //     player.off('jatszok');
                //     player.off('megyek');
                //     player.off('bedobom');
                // });
            }
        });
        player.on('megyek', () => {
            finplayers.push(player);
            finplayerindexes.push(idx);
            //console.log(finplayerindexes);
        });
        player.on('bedobom', (arr) => {
            //console.log(leftover);
            leftover = leftover.concat(arr);
            spectators.push(player);
            //console.log(leftover);
        });
    });
}






io.on('connection', (sock) => {
    console.log('Someone connected');
    sock.on('name', (text) => {
        players.push(text);
        playerIds.push(sock.id);
        playerSockets.push(sock);
        console.log('Belepett ' + text + ' ID: ' + sock.id);
        var tmplayers = [];
        var tmplayerids = [];
        var tmplayersock = [];
        playerIds.forEach((id, idx) => {
            if (io.sockets.connected[id]) { 
                tmplayers.push(players[idx]);
                tmplayerids.push(playerIds[idx]);
                tmplayersock.push(playerSockets[idx]); 
            }
        });
        players = tmplayers;
        playerIds = tmplayerids;
        playerSockets = tmplayersock;
        io.emit('plist', players.join("<br/>"));
        if (playerIds.length > 2){
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
        var tmplayers = [];
        var tmplayerids = [];
        var tmplayersock = [];
        playerIds.forEach((id, idx) => {
            if (io.sockets.connected[id]) { 
                tmplayers.push(players[idx]);
                tmplayerids.push(playerIds[idx]);
                tmplayersock.push(playerSockets[idx]); 
            }
            // console.log(tmplayers.length);
            // console.log(tmplayerids.length);
            // console.log(tmplayersock.length);
        });
        players = tmplayers;
        playerIds = tmplayerids;
        playerSockets = tmplayersock;
        // console.log(players.length);
        // console.log(playerIds.length);
        // console.log(playerSockets.length);
        io.emit('plist', players.join("<br/>"));
        //start a game
        UltiGame(players, playerIds, playerSockets);
    });
})

server.on('error', (err) => {
    console.error('Server error:', err);
})

server.listen(8000, () => {
    console.log('Ulti started on 8000');
});