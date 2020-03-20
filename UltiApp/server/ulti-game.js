class UltiGame {
    constructor(ps, pids, psocks){
        this._playerids = pids;
        this._players = ps;
        this._psocks = psocks;
        this._finplayers = [];
        this._finplayerindexes = [];
        this._spectators = [];
        this._frontwinner;
        this._cards = ['M1.png', 'M2.png', 'M3.png', 'M4.png', 'M5.png', 'M6.png', 'M7.png', 'M8.png', 'P1.png', 'P2.png', 'P3.png', 'P4.png', 'P5.png', 'P6.png', 'P7.png', 'P8.png', 'T1.png', 'T2.png', 'T3.png', 'T4.png', 'T5.png', 'T6.png', 'T7.png', 'T8.png', 'Z1.png', 'Z2.png', 'Z3.png', 'Z4.png', 'Z5.png', 'Z6.png', 'Z7.png', 'Z8.png'];
        this._sendToPlayers('Induljon a parti');
        var aktdeck = this._shuffle(this._cards);
        var pass1 = 0;
        var cnt= 0;
        this._psocks.forEach(s => {
            s.emit('elolrol', aktdeck.slice(cnt, cnt+5));
            cnt += 5;
        });
        var leftover = aktdeck.slice(cnt);

        this._psocks.forEach((player, idx) => {
            player.on('jatszok', () => {
                if (this._finplayers.length == 2){
                    this._frontwinner = player;
                    this._finplayers.push(player);
                    this._finplayerindexes.push(idx);
                    leftover = this._shuffle(leftover);
                    cnt = 0;
                    this._finplayers.forEach(s => {
                        s.emit('hatulrol', leftover.slice(cnt, cnt+5));
                        cnt += 5;
                    });
                    this._spectators.forEach(s => {
                        s.emit('nezelod');
                    });
                }
            });
            player.on('megyek', () => {
                this._finplayers.push(player);
                this._finplayerindexes.push(idx);
                console.log(this._finplayerindexes);
            });
            player.on('bedobom', (arr) => {
                leftover = leftover.concat(arr);
                this._spectators.push(player);
            });
        });
    }
    _shuffle(arr) {
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
    // _sendToPlayer(playerIndex, msg){
    //     this._players[playerIndex].emit('message', msg);
    // }
    _sendToPlayers(msg){
        this._psocks.forEach(sock => {
            sock.emit('message', msg)
        })
    }
    // _onTurn(playerIndex, turn){
    //     this._turns[playerIndex] = turn;
    //     this._sendToPlayer(playerIndex, `You selected ${turn}`);
    //     this._checkGameOver();
    // }
    // _checkGameOver(){
    //     const turns = this._turns;
    //     if (turns[0] && turns[1]){
    //         this._sendToPlayers('Game over ' + turns.join(' : '));
    //         this._getGameResult();
    //         this._turns = [null, null];
    //         this._sendToPlayers('Next round!');
    //     }
    // }
    // _getGameResult(){
    //     const p0 = this._decodeTurn(this._turns[0]);
    //     const p1 = this._decodeTurn(this._turns[1]);
    //     const distance = (p1 - p0 + 3) % 3;
    //     switch (distance){
    //         case 0:
    //             // draw
    //             this._sendToPlayers('Draw!');
    //             break;
    //         case 1:
    //             // p0 won
    //             this._sendWinMessage(this._players[0], this._players[1]);
    //             break;
    //         case 2:
    //             // p1 won
    //             this._sendWinMessage(this._players[1], this._players[0]);
    //             break;
    //     }
    // }
    // _sendWinMessage(winner, looser){
    //     winner.emit('message', "You won!");
    //     looser.emit('message', "You lost!");
    // }
    // _decodeTurn(turn){
    //     switch (turn){
    //         case 'rock':
    //             return 0;
    //         case 'scissors':
    //             return 1;
    //         case 'paper':
    //             return 2;
    //         default:
    //             throw new Error(`Could not decode turn ${turn}`);
    //     }
    // }
}

module.exports = UltiGame;