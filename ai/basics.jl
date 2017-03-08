##############
#Cards, Rules and helper functions
##############
# import Base.show

#The 32 Cards
typealias Card Int #could be set to UInt8/Int to fit in memory and/or speed
const 🎃7 = t7 = Card(0)  #Tök hetes
const 🎃8 = t8 = Card(1)  #Tök nyolcas
const 🎃9 = t9 = Card(2)  #Tök kilences
const 🎃V = 🎃J = 🎃▽ = tj = tv = Card(3)  #Tök alsó
const 🎃F = tf = Card(4)  #Tök felső
const 🎃K = tk = Card(5)  #Tök király
const 🎃T = tt = Card(6)  #Tök tízes
const 🎃A = ta = Card(7)  #Tök ász
const 🍃7 = z7 = Card(8)  #Zöld hetes
const 🍃8 = z8 = Card(9)
const 🍃9 = z9 = Card(10)
const 🍃V = 🍃J = 🍃▽ = zj = zv = Card(11)
const 🍃F = 🍃△ = zf = Card(12)
const 🍃K = 🍃♔ = zk = Card(13)
const 🍃T = 🍃10 = zt = Card(14)
const 🍃A = za = Card(15)
const 🌰7 = m7 = Card(16) #Makk hetes
const 🌰8 = m8 = Card(17)
const 🌰9 = m9 = Card(18)
const 🌰V = 🌰J = 🌰▽ = mj = mv = Card(19)
const 🌰F = mf = Card(20)
const 🌰K = mk = Card(21)
const 🌰T = mt = Card(22)
const 🌰A = ma = Card(23)
const ❤️️️️7 = p7 = Card(24) #Piros hetes
const ❤️️️️8 = p8 = Card(25)
const ❤️️️️9 = p9 = Card(26)
const ❤️️️️V = ❤️️️️J = ❤️️️️▽ = pj = pv = Card(27)
const ❤️️️️F = pf = Card(28)
const ❤️️️️K = pk = Card(29)
const ❤️️️️T = pt = Card(30)
const ❤️️️️A = pa = Card(31) #Piros ász
#@enum CARD T7=0 T8=1 T9=2 TA=3 TF=4 TK=5 TT=6 TS=7 Z7=8 Z8=9 Z9=10 ZA=11 ZF=12 ZK=13 ZT=14 ZS=15 M7=16 M8=17 M9=18 MA=19 MF=20 MK=21 MT=22 MS=23 P7=24 P8=25 P9=26 PA=27 PF=28 PK=29 PT=30 PS=31
#TODO cards = Dict((Card0, "🎃 7"), <<<etc.>>>)
cards = [ "🎃 7", "🎃 8", "🎃 9", "🎃 V", "🎃 F", "🎃 K", "🎃 T", "🎃 A", "🍃 7", "🍃 8", "🍃 9", "🍃 V", "🍃 F", "🍃 K", "🍃 T", "🍃 A", "🌰 7", "🌰 8", "🌰 9", "🌰 V", "🌰 F", "🌰 K", "🌰 T", "🌰 A", "❤️️ ️️7", "❤️️ ️️8", "❤️️ ️️9", "❤️️ ️️V", "❤️️️️ ️️F", "❤️️ ️️K", "❤️️ ️️T", "❤️️ ️️A"]

typealias Suit Int
const 🎃 = t = Suit(0) #Tök
const 🍃 = z = Suit(1) #Zöld
const 🌰 = m = Suit(2) #Makk
const ❤️ = p = Suit(3) #Piros
const notrump = Suit(4) #Szín nélküli (ászkirályos)
const undecided = Suit(5) #Még nem tudjuk (hátulról bemondott négy tízesnélÖ
#@enum SUIT T=0 Z=1 M=2 P=3 NOTRUMP=4
const suitValues = Dict([(t, 3), (z, 4), (m, 5), (p, 6)]) #Halloween-kor TOK = 7 :)

typealias Face Int
const f7 = Face(0) #hetes
const f8 = Face(1) #nyolcas
const f9 = Face(2) #kilences
const fv=fj = Face(3) #alsó
const ff = Face(4) #felső
const fk = Face(5) #király
const ft = Face(6) #tízes
const fa = Face(7) #ász
#@enum FACE _7=0 _8=1 _9=2 A=3 F=4 K=5 _10=6 S=7

SuitFace(card::Card) = Suit(div(card, Card(8))), Face(rem(card, Card(8)))
SuitFace(suit::Suit, face::Face) = Card(Card(8) * suit + face)

function trumps(card1::Card, card2::Card, trump::Suit)
    suit1, face1 = SuitFace(card1)
    suit2, face2 = SuitFace(card2)

    if suit1 != suit2
        return suit1 == trump
    elseif trump != notrump #szines jateknal a sorrend pontos
        face1 > face2
    else #szintelen jateknal a tizes alulra megy, a kilences es az also koze
        if face1 == ft face1 = 2.5 end
        if face2 == ft face2 = 2.5 end
        return face1 > face2
    end
end

# function trumps(card1::Card, cards::Array{Card, 1}, trump::Suit)
#
# end

typealias AlapBemondas Int
const parti = passz = AlapBemondas(1)
const _40_100 = negyvenSzaz = AlapBemondas(2)
const ulti = AlapBemondas(3)
const repulo = AlapBemondas(4)
const _4_asz = negyAsz = AlapBemondas(5)
const betli = AlapBemondas(6)
const durchmars = AlapBemondas(7)
const _20_100 = huszSzaz = AlapBemondas(8)
const _4_10 = negyTizes = AlapBemondas(9)
const rebetli = teritettBetli = AlapBemondas(10)
const redurchmars = teritettDurchmars = AlapBemondas(11)
const AlapBemondasValues = [1, 4, 4, 4, 4, 30, 6, 8, 55, 20, 12]
#const alapBemondasok = [("Passz", 1), ("40-100", 4) <<<stb.>>>]

#TODO: teritett, szinnelkuli, stb.
#TODO: enum? dict (ertekkel)?
typealias Modosito Int
const _4x = elolrol = Modosito(4)
const _2x = ramondva = Modosito(2)
const _1x = hatulrol = Modosito(1)

typealias Kontra Int
const E = Kontra(4)
const H = Kontra(2)

typealias Kontrak Array{Kontra} #pl. Kontrak([E,E,H]) az elolrol kontra, elolrol rekontra es hatulrol szub - 32x

# function show(Kontrak) end #kiirja a kontra, re, szub, mord, stb. -t

#Egy alapbemondas modositokkal
#TODO: immutable?
immutable ContractElement
    modosito::Modosito
    bem::AlapBemondas
    kon::Kontrak
    val::Number
 end

#A bemondas
immutable Contract
    suit::Suit
    contracts::Array{ContractElement}
    totalvalue::Number
 end

contractValues = Dict{Tuple{Suit,AlapBemondas,Modosito}, Int}()

#TODO mit lehet elolrol hatulrol es ramondva bemondani
#szines bemondasok
for suit in [t, z, m, p]
    for bem in [parti, negyvenSzaz, ulti, repulo, negyAsz, durchmars, huszSzaz, rebetli, redurchmars]
        for honnan in [elolrol, ramondva, hatulrol]
            println(suit, " ", bem, " ", honnan, " -> ", honnan * suitValues[suit] * AlapBemondasValues[bem])
            contractValues[(suit, bem, honnan)] = honnan * suitValues[suit] * AlapBemondasValues[bem]
        end
    end
end

#negy tizes es szintelen bemondasok
contractValues[(t, negyTizes, ramondva)] = 192
contractValues[(z, negyTizes, ramondva)] = 192
contractValues[(m, negyTizes, ramondva)] = 192
contractValues[(p, negyTizes, ramondva)] = 192
contractValues[(t, negyTizes, hatulrol)] = 55
contractValues[(z, negyTizes, hatulrol)] = 55
contractValues[(m, negyTizes, hatulrol)] = 55
contractValues[(p, negyTizes, hatulrol)] = 55
contractValues[(undecided, negyTizes, hatulrol)] = 55
contractValues[(notrump, betli, hatulrol)] = 30
contractValues[(notrump, redurchmars, hatulrol)] = 144
