let userName = null;

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
    x.style.bottom = "60px";
}
function moveCardBack(x){
    x.style.bottom = "20px";
}
function alertmessage(x){
    alert("you clicked on " + x.id + "!");
}

var cards = ['M7.png', 'MD.png', 'P7.png', 'PD.png', 'T7.png', 'TD.png', 'Z7.png', 'ZD.png', 'M8.png', 'MF.png', 'P8.png', 'PF.png', 'T8.png', 'TF.png', 'Z8.png', 'ZF.png', 'M9.png', 'MK.png', 'P9.png', 'PK.png', 'T9.png', 'TK.png', 'Z9.png', 'ZK.png', 'MA.png', 'MX.png', 'PA.png', 'PX.png', 'TA.png', 'TX.png', 'ZA.png', 'ZX.png'];


const onEntrySubmitted = (e) => {
    e.preventDefault();
    const input = document.querySelector('#name');
    userName = input.value;
    if (userName){
        const writeEvent = (text) => {
            // <ul> element
            const parent = document.querySelector('#events');
            // <li> element
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

        // const addButtonListeners = () => {
        //     ['rock', 'paper', 'scissors'].forEach((id) =>{
        //         const button = document.getElementById(id);
        //         button.addEventListener('click', () => {
        //             sock.emit('turn', id);
        //         });
        //     });
        // };
        var x = document.getElementById("entry");
        x.style.display = "none";
        x = document.getElementById("mainblock");
        x.style.display = "flex";
        var x = document.getElementById("start-game");
        x.style.display = "none";
        writeEvent('Otlapos Ulti beszelgetes');

        const sock = io();
        sock.on('message', (text) => {
            writeEvent(text);
        });
        sock.on('plist', (text) => {
            writePlayerList("Belepett jatekosok:<br/>" + text);
        });
        sock.on('canstart', () => {
            var x = document.getElementById("start-game");
            x.style.display = "block";
            cards.forEach(imageFile => {
                var id = imageFile.substring(0,2);
                const parent = document.querySelector('#gameplace');
                const g = document.createElement('div');
                g.setAttribute("id", id);
                g.setAttribute("class", "largecard");
                g.setAttribute("style", "display: none; bottom: 20px");
                g.setAttribute("onclick", "alertmessage(this)");
                g.setAttribute("onmouseover", "moveCardUp(this)");
                g.setAttribute("onmouseout", "moveCardBack(this)");
                p = document.createElement("img");
                p.setAttribute("src", "cards/" + imageFile);
                g.appendChild(p);
                parent.appendChild(g);
                // var d = document.getElementById(id);
                // d.style.display = "hide";
            });
            cards = shuffle(cards);
            for (i = 0; i < 10; i++){
                var id = cards[i].substring(0,2);
                x = document.getElementById(id);
                x.style.display = "block";
                x.style.left = (20 + i * 60) + "px";
                x.style.zIndex = i;
            }
            document.querySelector('#start-game').addEventListener('submit', onStartGame);
        });
        document.querySelector('#chat-form').addEventListener('submit', onFormSubmitted);
        //addButtonListeners();
        sock.emit('name', userName);
    }
    
};




if (userName == null){
    var x = document.getElementById("mainblock");
    x.style.display = "none";
    document.querySelector('#entry-form').addEventListener('submit', onEntrySubmitted);
}