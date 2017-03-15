##############
#Cards, Rules and helper functions
##############
import Base: show, <, *

#The 32 Cards
#Tok 7es-tol (t7) piros Aszig (pA).
#Note: az also U, mint "Unter Knabe" from the original German deck
@enum(Card,
    t7=0,  t8=1,  t9=2,  tU=3,  tF=4,  tK=5,  tT=6,  tA=7,
    z7=8 , z8=9 , z9=10, zU=11, zF=12, zK=13, zT=14, zA=15,
    m7=16, m8=17, m9=18, mU=19, mF=20, mK=21, mT=22, mA=23,
    p7=24, p8=25, p9=26, pU=27, pF=28, pK=29, pT=30, pA=31)

const deck = Dict([
    (t7,"🎃 7"), (t8,"🎃 8"), (t9,"🎃 9"), (tU,"🎃 U"), (tF,"🎃 F"), (tK,"🎃 K"), (tT,"🎃 T"), (tA,"🎃 A"),
    (z7,"🍃 7"), (z8,"🍃 8"), (z9,"🍃 9"), (zU,"🍃 U"), (zF,"🍃 F"), (zK,"🍃 K"), (zT,"🍃 T"), (zA,"🍃 A"),
    (m7,"🌰 7"), (m8,"🌰 8"), (m9,"🌰 9"), (mU,"🌰 U"), (mF,"🌰 F"), (mK,"🌰 K"), (mT,"🌰 T"), (mA,"🌰 A"),
    (p7,"❤️️ ️️7"), (p8,"❤️️ ️️8"), (p9,"❤️️ ️️9"), (pU,"❤️️ ️️U"), (pF,"❤️️️️ ️️F"), (pK,"❤️️ ️️K"), (pT,"❤️️ ️️T"), (pA,"❤️️ ️️A")])

#overloading for comparison and sort
function <(card1::Card, card2::Card)
    Int(card1) < Int(card2)
end

@enum(Suit,
    t = 0, #Tök
    z = 1, #Zöld
    m = 2, #Makk
    p = 3, #Piros
    notrump = 4, #Szín nélküli (ászkirályos)
    undecided = 5) #Még nem tudjuk (hátulról bemondott négy tízesnélÖ
const suitProperties = Dict([
    (t, (["Tök", "tok", "🎃", "t"], 3)),
    (z, (["Zöld", "zold", "🍃", "z"], 4)),
    (m, (["Makk", "🌰", "m"], 5)),
    (p, (["Piros", "❤️️", "p"], 6))]) #Halloween-kor TOK = 7 :)

@enum(Face,
    _7 = 0, #hetes
    _8 = 1, #nyolcas
    _9 = 2, #kilences
    # _10 = 2.5, #tizes (szintelen jateknal)
    U = 3, #alsó
    F = 4, #felső
    K = 5, #király
    T = 6, #tízes
    A = 7) #ász
# const faceProperties = Dict([
#     (_7, (["Hetes", "7"], 3)),
# ) :)

#TODO const faceProperties = Dict([(t, ("Tök", 3)), (z, ("Zöld", 4)), (m, ("Makk", 5)), (p, ("Piros", 6))]) #Halloween-kor TOK = 7 :)

SuitFace(card::Card) = Suit(div(Int(card), 8)), Face(rem(Int(card), 8))
SuitFace(suit::Suit, face::Face) = Card(8 * Int(suit) + Int(face))
function *(suit::Suit, face::Face)
    SuitFace(suit, face)
end

#compare two cards using the trump suit
function trumps(card1::Card, card2::Card, trump::Suit)
    suit1, face1 = SuitFace(card1)
    suit2, face2 = SuitFace(card2)

    if suit1 != suit2
        return suit1 == trump
    else
        face1 = Int(face1)
        face2 = Int(face2)
        if trump == notrump #szintelen jateknal a tizes alulra megy, a kilences es az also koze
            if Int(_9) < face1 != Int(T) face1 += 4 end #UFK a T fole
            if Int(_9) < face2 != Int(T) face2 += 4 end #UFK a T fole
        end
        return face1 > face2
    end
end

#compare one card to a set using the trump suit
function trumps(card1::Card, cards::Array{Card, 1}, trump::Suit)
    for card in cards
        if trumps(card, card1, trump) return false end
    end
    return true #no card trumped me
end

#returns the index of the largest card in a set using the trump suit
function largestCard(cards::Array{Card,1}, trump::Suit)
    assert(length(cards) > 0)
    if length(cards) == 1 return 1 end
    for i in 1:(length(cards) - 1) #TODO iterator
        if trumps(cards[i], cards[i + 1:end], trump)
            return i
        end
    end
    assert(trumps(cards[end], cards[1:end-1], trump))
    return length(cards) #last one
end


#Bemondasok
# abban a sorrendben, ahogy egymashoz fuzik oket (ulti-repulo-40_100-negyAsz-durchmars)
@enum(AlapBemondas,
    semmi = 0, #amig nincs semmi
    ulti = 1,
    repulo = 2,
    negyvenSzaz = 3,
    huszSzaz = 4,
    negyAsz = 5,
    durchmars = 6,
    redurchmars = 7,
    parti = passz = 8,
    betli = 9,
    rebetli = 10,
    negyTizes = 11,
    csendesUlti = 12,
    csendesDuri = 13,
    )
#Bemondasok erteke es nevei (elso nev lesz kiirva)
const alapBemondasProperties = Dict([
  (semmi,       (0, ["", "semmi"])),
  (ulti,        (4, ["Ulti", "ultimo"])),
  (repulo,      (4, ["Repülő", "repulo"], )),
  (negyvenSzaz, (4, ["40-100", "40 100", "40_100", "negyvenSzaz", "negyvenSzáz", "Negyven Szaz", "Negyven Száz"])),
  (huszSzaz,    (8, ["20-100", "20 100", "20_100", "huszSzaz", "húszSzáz", "Husz Szaz", "Húsz Száz"])),
  (negyAsz,     (4, ["4 Ász", "4 Asz", "negyAsz", "NégyÁsz", "Negy Asz", "Négy Ász"])),
  (durchmars,   (6, ["Durchmars"])),
  (redurchmars, (12, ["Terített Durchmars", "redurchmars"])),
  (parti,       (1, ["Passz", "Parti"])),
  (betli,       (30, ["Betli"])), #mert szintelen, nincs szorzo
  (rebetli,     (20, ["Terített Betli", "rebetli"])),
  (negyTizes,   (55, ["4 Tízes", "4 Tizes", "negyTizes", "NégyTízes", "Negy Tizes", "Négy Tízes"])),
])

#Modosito szorzok elolrol bemondott vagy ramondott bemondasokra
@enum(Modosito,
    elolrol =  4,
    ramondva = 2,
    hatulrol = 1,
)
const modositoProperties = Dict([
  (elolrol,  ["Elölről",  "Elolrol",  "E"]),
  (ramondva, ["Rámondva", "ramondva", "R"]),
  (hatulrol, ["Hátulról", "hatulrol", "H"]),
])


@enum(Kontra,
    EK = 4,
    HK = 2,
)
const kontraProperties = Dict([
  (EK, ["Elölről kontra",  "EK"]),
  (EK, ["Hátulról kontra", "HK"]),
])
typealias Kontrak Array{Kontra, 1} #pl. Kontrak([EK,EK,HK]) az elolrol kontra, elolrol rekontra es hatulrol szub - 32x

# function show(Kontrak) end #kiirja a kontra, re, szub, mord, stb. -t

#Egy alapbemondas modositokkal
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
            contractValues[(suit, bem, honnan)] = Int(honnan) * suitProperties[suit][2] * alapBemondasProperties[bem][1]
        end
    end
end
#negy tizes
for suit in [t,z,m,p]
    contractValues[(suit, negyTizes, ramondva)] = 192
    contractValues[(suit, negyTizes, hatulrol)] = 55
end
#szintelen bemondasok
contractValues[(undecided, negyTizes, hatulrol)] = 55
contractValues[(notrump, betli, hatulrol)] = 30
contractValues[(notrump, redurchmars, hatulrol)] = 144

#all the strings needed for parsing lookups
# parseTokens = Vector()
# for properties in [suitProperties, faceProperties, deck, alapBemondasProperties, modositoProperties, kontraProperties]
#     for (key, val) in properties
#       #TODO
#         if isa(String, val)
#     end
# end
#
function show(io::IO, contract::Contract, shortFormat=false)
    print(io, "Bemondás: ")

end

function parseContract(contract::String)

end

##############
#Tests
##############
