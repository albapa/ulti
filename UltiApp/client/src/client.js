let userName = null;

var cards = ['M1.png', 'M2.png', 'M3.png', 'M4.png', 'M5.png', 'M6.png', 'M7.png', 'M8.png', 'P1.png', 'P2.png', 'P3.png', 'P4.png', 'P5.png', 'P6.png', 'P7.png', 'P8.png', 'T1.png', 'T2.png', 'T3.png', 'T4.png', 'T5.png', 'T6.png', 'T7.png', 'T8.png', 'Z1.png', 'Z2.png', 'Z3.png', 'Z4.png', 'Z5.png', 'Z6.png', 'Z7.png', 'Z8.png'];

var hand = [];
var state = "elol";
var talon = [];

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

function clearTable(){
    cards.forEach(c => {
        var id = c.substring(0,2);
        x = document.getElementById(id);
        x.style.display = "none";
    });
}
function playcard(id){
    var tid = id + ".png";
    if (state == "talonozas"){
        if (hand.length > 10) {
            
        }
    }
    if (state == "lejatszas"){
        var x = document.getElementById(id);
        x.style.display = "none";
        id = id + ".png";
        sock.emit('playcard', id);
        var tmhand = [];
        hand.forEach(c => {
            if (c != id){
                tmhand.push(c);
            }
        });
        hand = tmhand;
        showCards(hand);
    }
}
function showCards (arr){
    arr.sort();
    for (i = 0; i < arr.length; i++){
        var id = arr[i].substring(0,2);
        x = document.getElementById(id);
        x.style.display = "block";
        x.style.left = (20 + i * 60) + "px";
        x.style.zIndex = i;
    }
}


const sock = io();

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
const onBedobom = (e) => {
    e.preventDefault();
    sock.emit('bedobom', hand);
    butt_arr.forEach(x => {
        x = document.getElementById(x + "-butt");
        x.style.display = "none";
    });
    sock.emit('message', userName + ": bedobta");
}
const onMegyek = (e) => {
    e.preventDefault();
    sock.emit('megyek');
    butt_arr.forEach(x => {
        x = document.getElementById(x + "-butt");
        x.style.display = "none";
    });
    sock.emit('message', userName + ": megy tovabb");
}
const onJatszok = (e) => {
    e.preventDefault();
    sock.emit('jatszok');
    butt_arr.forEach(x => {
        x = document.getElementById(x + "-butt");
        x.style.display = "none";
    });
    sock.emit('message', userName + ": jatszik");
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
    // var d = document.getElementById(id);
    // d.style.display = "hide";
});
var butt_arr = ["bedobom", "megyek", "jatszok"];
var spacer = 0;
butt_arr.forEach(val=> {
    const dv = document.createElement('div');
    dv.setAttribute("id", val + "-butt");
    dv.setAttribute("class", "elolrol-butt");
    dv.setAttribute("style", "display: none; bottom: 300px; left: " + (spacer+100) + "px");
    const fr = document.createElement('form');
    fr.setAttribute("id", val + "-form");
    const bt = document.createElement('button');
    bt.innerText = val.charAt(0).toUpperCase() + val.slice(1);
    fr.appendChild(bt);
    dv.appendChild(fr);
    parent.appendChild(dv);
    spacer+=120;
})
document.querySelector('#start-game').addEventListener('submit', onStartGame);
document.querySelector('#bedobom-form').addEventListener('submit', onBedobom);
document.querySelector('#megyek-form').addEventListener('submit', onMegyek);
document.querySelector('#jatszok-form').addEventListener('submit', onJatszok);
document.querySelector('#chat-form').addEventListener('submit', onFormSubmitted);

const onEntrySubmitted = (e) => {
    e.preventDefault();
    const input = document.querySelector('#name');
    userName = input.value;
    if (userName){
       

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

        
        sock.on('message', (text) => {
            writeEvent(text);
        });
        sock.on('plist', (text) => {
            writePlayerList("Belepett jatekosok:<br/>" + text);
        });
        sock.on('canstart', () => {
            var x = document.getElementById("start-game");
            x.style.display = "block";
        });
        sock.on('elolrol', (subarr)=>{
            clearTable();
            hand = [];
            hand = hand.concat(subarr);
            showCards(hand);
            butt_arr.forEach(x => {
                x = document.getElementById(x + "-butt");
                x.style.display = "block";
            });
        });
        sock.on('hatulrol', (arr) => {
            clearTable();
            hand = hand.concat(arr);
            showCards(hand);
            state = "talonozas";
        });
        sock.on('nezelod', () => {
            document.removeEventListener('submit', onBedobom);
            document.removeEventListener('submit', onMegyek);
            document.removeEventListener('submit', onJatszok);
            clearTable();
        });
        
        //addButtonListeners();
        sock.emit('name', userName);
    }
    
};




if (userName == null){
    var x = document.getElementById("mainblock");
    x.style.display = "none";
    document.querySelector('#entry-form').addEventListener('submit', onEntrySubmitted);
}