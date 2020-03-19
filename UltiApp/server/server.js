const http = require('http');
const express = require('express');
const socketio = require('socket.io');
const UltiGame = require('./ulti-game');

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
        });
        players = tmplayers;
        playerIds = tmplayerids;
        playerSockets = tmplayersock;
        //start a game
        new UltiGame(players, playerIds, playerSockets);
    });
})

server.on('error', (err) => {
    console.error('Server error:', err);
})

server.listen(8000, () => {
    console.log('Ulti started on 8000');
});