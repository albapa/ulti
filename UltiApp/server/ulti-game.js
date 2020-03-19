class UltiGame {
    constructor(ps, pids, psocks){
        this._playerids = pids;
        this._players = ps;
        this._psocks = psocks;
        this._cards = ['M7.png', 'MD.png', 'P7.png', 'PD.png', 'T7.png', 'TD.png', 'Z7.png', 'ZD.png', 'M8.png', 'MF.png', 'P8.png', 'PF.png', 'T8.png', 'TF.png', 'Z8.png', 'ZF.png', 'M9.png', 'MK.png', 'P9.png', 'PK.png', 'T9.png', 'TK.png', 'Z9.png', 'ZK.png', 'MA.png', 'MX.png', 'PA.png', 'PX.png', 'TA.png', 'TX.png', 'ZA.png', 'ZX.png'];
        this._sendToPlayers('Induljon a parti');

        // this._players.forEach((player, idx) => {
        //     player.on('turn', (turn) => {
        //         this._onTurn(idx, turn);
        //     });
        // });
    }
    _sendToPlayer(playerIndex, msg){
        this._players[playerIndex].emit('message', msg);
    }
    _sendToPlayers(msg){
        this._psocks.forEach(sock => {
            sock.emit('message', msg)
        })
    }
    _onTurn(playerIndex, turn){
        this._turns[playerIndex] = turn;
        this._sendToPlayer(playerIndex, `You selected ${turn}`);
        this._checkGameOver();
    }
    _checkGameOver(){
        const turns = this._turns;
        if (turns[0] && turns[1]){
            this._sendToPlayers('Game over ' + turns.join(' : '));
            this._getGameResult();
            this._turns = [null, null];
            this._sendToPlayers('Next round!');
        }
    }
    _getGameResult(){
        const p0 = this._decodeTurn(this._turns[0]);
        const p1 = this._decodeTurn(this._turns[1]);
        const distance = (p1 - p0 + 3) % 3;
        switch (distance){
            case 0:
                // draw
                this._sendToPlayers('Draw!');
                break;
            case 1:
                // p0 won
                this._sendWinMessage(this._players[0], this._players[1]);
                break;
            case 2:
                // p1 won
                this._sendWinMessage(this._players[1], this._players[0]);
                break;
        }
    }
    _sendWinMessage(winner, looser){
        winner.emit('message', "You won!");
        looser.emit('message', "You lost!");
    }
    _decodeTurn(turn){
        switch (turn){
            case 'rock':
                return 0;
            case 'scissors':
                return 1;
            case 'paper':
                return 2;
            default:
                throw new Error(`Could not decode turn ${turn}`);
        }
    }
}

module.exports = UltiGame;