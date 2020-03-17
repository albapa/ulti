##############
#Cards, Rules and helper functions
##############
include("IntSet32.jl")
using Memoize
import Base: show, <, copy, print, isequal, ==, length
DEBUG = true
UNSAFE = false #@assert , type safety, etc. off

#The 32 Cards
#Tok 7es-tol (t7) piros Aszig (pA).
#Note: az also U, mint "Unter Knabe" from the original German deck

const t7 = CardSet32(UInt32(1) << 0)
const t8 = CardSet32(UInt32(1) << 1)
const t9 = CardSet32(UInt32(1) << 2)
const tU = CardSet32(UInt32(1) << 3)
const tF = CardSet32(UInt32(1) << 4)
const tK = CardSet32(UInt32(1) << 5)
const tT = CardSet32(UInt32(1) << 6)
const tA = CardSet32(UInt32(1) << 7)

const z7 = CardSet32(UInt32(1) << 8 )
const z8 = CardSet32(UInt32(1) << 9 )
const z9 = CardSet32(UInt32(1) << 10)
const zU = CardSet32(UInt32(1) << 11)
const zF = CardSet32(UInt32(1) << 12)
const zK = CardSet32(UInt32(1) << 13)
const zT = CardSet32(UInt32(1) << 14)
const zA = CardSet32(UInt32(1) << 15)

const m7 = CardSet32(UInt32(1) << 16)
const m8 = CardSet32(UInt32(1) << 17)
const m9 = CardSet32(UInt32(1) << 18)
const mU = CardSet32(UInt32(1) << 19)
const mF = CardSet32(UInt32(1) << 20)
const mK = CardSet32(UInt32(1) << 21)
const mT = CardSet32(UInt32(1) << 22)
const mA = CardSet32(UInt32(1) << 23)

const p7 = CardSet32(UInt32(1) << 24)
const p8 = CardSet32(UInt32(1) << 25)
const p9 = CardSet32(UInt32(1) << 26)
const pU = CardSet32(UInt32(1) << 27)
const pF = CardSet32(UInt32(1) << 28)
const pK = CardSet32(UInt32(1) << 29)
const pT = CardSet32(UInt32(1) << 30)
const pA = CardSet32(UInt32(1) << 31)

const fulldeck = anycard = xX = 🌠 = CardSet32(0xFFFFFFFF)
const emptydeck = nocard = ⬜ =CardSet32(0x00000000)

const deck = Dict([
    t7 => ("t7", "🎃 7"), t8 => ("t8", "🎃 8"), t9 => ("t9", "🎃 9"), tU => ("tU", "🎃 U"), tF => ("tF", "🎃 F"), tK => ("tK", "🎃 K"), tT => ("tT", "🎃 T"), tA => ("tA", "🎃 A"),
    z7 => ("z7", "🍃 7"), z8 => ("z8", "🍃 8"), z9 => ("z9", "🍃 9"), zU => ("zU", "🍃 U"), zF => ("zF", "🍃 F"), zK => ("zK", "🍃 K"), zT => ("zT", "🍃 T"), zA => ("zA", "🍃 A"),
    m7 => ("m7", "🌰 7"), m8 => ("m8", "🌰 8"), m9 => ("m9", "🌰 9"), mU => ("mU", "🌰 U"), mF => ("mF", "🌰 F"), mK => ("mK", "🌰 K"), mT => ("mT", "🌰 T"), mA => ("mA", "🌰 A"),
    p7 => ("p7", "❤️️ ️️7"), p8 => ("p8", "❤️️ ️️8"), p9 => ("p9", "❤️️ ️️9"), pU => ("pU", "❤️️ ️️U"), pF => ("pF", "❤️️️️ ️️F"), pK => ("pK", "❤️️ ️️K"), pT => ("pT", "❤️️ ️️T"), pA => ("pA", "❤️️ ️️A")])


function print(io::IO, cs::CardSet32, shortForm=true)
    if isempty(cs) return end

    if shortForm
        currentSuit = notrump
        for card in cs
            suit, face = SuitFace(card)
            if suit == currentSuit 
                print(io, faceProperties[face][end])
            else
                print(io, deck[card][1])
                currentSuit = suit
            end
        end
    else    
        for card in cs
          print(io, deck[card][2], " ")
        end
    end
end

function print(io::IO, cs::Vector{CardSet32}, shortForm=true)
    for crd in cs
      print(io, crd, shortForm); println()
    end
end
function print(io::IO, cs::Vector{Vector{CardSet32}}, shortForm=true)
    for crd in cs
      print(io, crd, shortForm); println("---")
    end
end

display(cs::CardSet32) = print(stdout, cs, false)
display(cs::Vector{CardSet32}) = print(stdout, cs, false)
display(cs::Vector{Vector{CardSet32}}) = print(stdout, cs, false)

const Suit = CardSet32
    const t = union(t7,t8,t9,tU,tF,tK,tT,tA) #Tök
    const z = union(z7,z8,z9,zU,zF,zK,zT,zA) #Zöld
    const m = union(m7,m8,m9,mU,mF,mK,mT,mA) #Makk
    const p = union(p7,p8,p9,pU,pF,pK,pT,pA) #Piros
    const nosuit = notrump = CardSet32() #Szín nélküli (ászkirályos) vagy még nem tudjuk (pl. hátulról bemondott négy tízesnélÖ
    const anySuit = union(t, z, m, p) #any
    const a = b = c = d = CardSet32() #undefined... yet

const suitProperties = Dict([
    (t, (["Tök", "tok", "🎃", "t"], 3)), #Halloween-kor TOK = 7 :)
    (z, (["Zöld", "zold", "🍃", "z"], 4)),
    (m, (["Makk", "🌰", "m"], 5)),
    (p, (["Piros", "❤️️", "p"], 6)), 
    (notrump, (["Színtelen", "notrump", "sz", "n"], 1)),
    ]) 

const suitStrings = Dict([
    ('t', t),
    ('z', z),
    ('m', m),
    ('p', p),
    ('n', notrump),
    ('x', anySuit),
    ('a', a), #adu?
    ('b', b), 
    ('c', c),
    ('d', d),
    ]) 

const Face = CardSet32
    const _7 = union(t7, z7, m7, p7) #hetes
    const _8 = union(t8, z8, m8, p8) #nyolcas
    const _9 = union(t9, z9, m9, p9) #kilences
    const U  = union(tU, zU, mU, pU) #alsó
    const F  = union(tF, zF, mF, pF) #felső
    const K  = union(tK, zK, mK, pK) #király
    const T  = union(tT, zT, mT, pT) #tízes
    const A  = union(tA, zA, mA, pA) #ász
    const AT = union(T, A)
    const FK = union(F, K)    
    const _78 = union(_7, _8)    
    const X  = union(_7, _8, _9, U, F, K, T, A) #barmelyik
    const Y  = union(_7, _8, _9, U, F, K) #kicsi
    const Z  = union(_9, U, F, K)   #nem fontos

const faceProperties = Dict(
    _7 => ["Hetes", "7"],
    _8 => ["Nyolcas", "8"],
    _9 => ["Kilences", "9"],
    U => ["Alsó", "U"],
    F => ["Felső", "F"],
    K => ["Király", "K"],
    T => ["Tízes", "T"],
    A => ["Ász", "A"],
) 

const faceStrings = Dict(
    '7' => _7,
    '8' => _8,
    '9' => _9,
    'U' => U,
    'F' => F,
    'K' => K,
    'T' => T,
    'A' => A,
    "AT" => AT,
    "FK" => FK,
    "78" => _78,
    'X' => X,
    'Y' => Y,
    'Z' => Z,
) 
#TODO const faceProperties = Dict([(t, ("Tök", 3)), (z, ("Zöld", 4)), (m, ("Makk", 5)), (p, ("Piros", 6))]) #Halloween-kor TOK = 7 :)


const suitFace = Dict([
    t7 => (t, _7), t8 => (t, _8), t9 => (t, _9), tU => (t, U), tF => (t, F), tK => (t, K), tT => (t, T), tA => (t, A),
    z7 => (z, _7), z8 => (z, _8), z9 => (z, _9), zU => (z, U), zF => (z, F), zK => (z, K), zT => (z, T), zA => (z, A),
    m7 => (m, _7), m8 => (m, _8), m9 => (m, _9), mU => (m, U), mF => (m, F), mK => (m, K), mT => (m, T), mA => (m, A),
    p7 => (p, _7), p8 => (p, _8), p9 => (p, _9), pU => (p, U), pF => (p,F), pK => (p, K), pT => (p, T), pA => (p, A),
    (t, _7) => t7, (t, _8) => t8, (t, _9) => t9, (t, U) => tU, (t, F) => tF, (t, K) => tK, (t, T) => tT, (t, A) => tA,
    (z, _7) => z7, (z, _8) => z8, (z, _9) => z9, (z, U) => zU, (z, F) => zF, (z, K) => zK, (z, T) => zT, (z, A) => zA,
    (m, _7) => m7, (m, _8) => m8, (m, _9) => m9, (m, U) => mU, (m, F) => mF, (m, K) => mK, (m, T) => mT, (m, A) => mA,
    (p, _7) => p7, (p, _8) => p8, (p, _9) => p9, (p, U) => pU, (p, F) => pF, (p, K) => pK, (p, T) => pT, (p, A) => pA])


SuitFace(card::Card) = suitFace[card]
suitof(card::Card) = suitFace[card][1]
faceof(card::Card) = suitFace[card][2]
# Card(suit::Suit, face::Face) = suitFace[(suit, face)]
Card(suit::Suit, face::Face) = intersect(suit, face)

#compare two cards using the trump suit
@memoize Dict function trumps(card1::Card, card2::Card, trump::Suit)
    suit1, face1 = SuitFace(card1)
    suit2, face2 = SuitFace(card2)

    if suit1 != suit2
        return suit1 == trump
    else
        face1 = UInt64(face1.cs) #to make sure the <<= will not overflow
        face2 = UInt64(face2.cs) 
        if trump == notrump #szintelen jateknal a tizes alulra megy, a kilences es az also koze
            if UInt64(_9.cs) < face1 != T face1 <<= 4 end #UFK a T fole, A meg feljebb
            if UInt64(_9.cs) < face2 != T face2 <<= 4 end #UFK a T fole, A meg feljebb
        end
        return face1 > face2 #MSBs are larger
    end
end

#TODO: trumping is a mess - rewrite
#support structure for trumping
largerThan = Dict{Tuple{Card, Suit}, CardSet32}()
for (card1, s1) in deck
    for (card2, s2) in deck
        for trump in [t, z, m, p, notrump]
            if !haskey(largerThan, (card1, trump)) 
                largerThan[(card1, trump)] = CardSet32()
            end
            if trumps(card2, card1, trump)
                largerThan[(card1, trump)] = union(card2, largerThan[(card1, trump)])
            end
        end
    end
end
function whichTrumps(cards::CardSet32, card::Card, trump::Suit)
    intersect(cards, largerThan[(card, trump)])
end

#returns the largest card in a set using the trump suit
@memoize Dict function largestCard(cards::CardSet32, trump::Suit, suit::Suit=trump) #TODO add currentSuit handling
    if length(cards) <= 1 return cards end
    card = first(cards)
    largerThanFirst = whichTrumps(cards, card, trump)
    if isempty(largerThanFirst) 
        if trumpsAll(card, setdiff(cards, card), trump) #if we have no trump, there is no largest card
            return card
        else
            throw(ArgumentError("no largest card in set - define suit!"))
            # return CardSet32()
        end
    else
        return largestCard(largerThanFirst, trump)
    end
end

@memoize Dict function smallestCard(cards::CardSet32, trump::Suit, suit::Suit=trump) #TODO add currentSuit handling
    if length(cards) <= 1 return cards end
    card = last(cards)
    if length(whichTrumps(cards, card, trump)) == length(cards) - 1 #trumped by all
        return card
    else
        return smallestCard(cards - card, trump) #TODO only works for sameSuit and trump
    end
end

#compare one card to a set using the trump suit
@memoize Dict function trumpsAll(card1::Card, cards::CardSet32, trump::Suit) 
    for card in cards
        if trumps(card, card1, trump) return false end
    end
    return true #no card trumped me
    # isempty(intersect(cards, largerThan[(card1, trump)])) #problem: suit (mA does not trump zT if trump is p)
end

@memoize Dict function trumpsNone(card1::Card, cards::CardSet32, trump::Suit) 
    for card in cards
        if trumps(card1, card, trump) return false end
    end
    return true #I trumped no card
    # isempty(intersect(cards, largerThan[(card1, trump)])) #problem: suit (mA does not trump zT if trump is p)
end

#Bemondasok
# abban a sorrendben, ahogy egymashoz fuzik oket (ulti-repulo-40_100-negyAsz-durchmars)
const AlapBemondas = UInt8
    semmi = UInt8(0) #amig nincs semmi
    ulti = UInt8(1)
    repulo = UInt8(2)
    negyvenSzaz = UInt8(3)
    huszSzaz = UInt8(4)
    negyAsz = UInt8(5)
    durchmars = UInt8(6)
    redurchmars = UInt8(7)
    parti = passz = UInt8(8)
    betli = UInt8(9)
    rebetli = UInt8(10)
    negyTizes = UInt8(11)
    csendesUlti = UInt8(12)
    csendesDuri = UInt8(13)
    
#Bemondasok erteke es nevei (elso nev lesz kiirva)
#TODO: value -> (licit, max, min)
const alapBemondasProperties = Dict([
  (semmi,       (0,  ["", "semmi", ""])),
  (ulti,        (4,  ["Ulti", "ultimo", "U", "Ult"])),
  (repulo,      (4,  ["Repülő", "repulo", "R", "Rep"], )),
  (negyvenSzaz, (4,  ["40-100", "40 100", "40_100", "negyvenSzaz", "negyvenSzáz", "Negyven Szaz", "Negyven Száz", "40s"])),
  (huszSzaz,    (8,  ["20-100", "20 100", "20_100", "huszSzaz", "húszSzáz", "Husz Szaz", "Húsz Száz", "20s"])),
  (negyAsz,     (4,  ["4 Ász", "4 Asz", "negyAsz", "NégyÁsz", "Negy Asz", "Négy Ász", "4A"])),
  (durchmars,   (6,  ["Durchmars", "Dur"])),
  (redurchmars, (12, ["Terített Durchmars", "redurchmars", "TDur"])),
  (parti,       (1,  ["Parti", "Passz", "P", "Par"])),
  (betli,       (30, ["Betli", "B", "Bet"])), #mert szintelen, nincs szorzo
  (rebetli,     (20, ["Terített Betli", "rebetli", "TBet"])),
  (negyTizes,   (55, ["4 Tízes", "4 Tizes", "negyTizes", "NégyTízes", "Negy Tizes", "Négy Tízes", "4T"])),
  (csendesUlti, (2,  ["Csendes Ulti", "CsendesUlti", "Csu", "CsU"])),
  # csendesDuri disabled due to computational needs and rarity
  # (csendesDuri, (3,  ["Csendes Durchmars", "Csendes Duri", "CsendesDuri", "Csd", "CsD"])),
])

#Modosito szorzok elolrol bemondott vagy ramondott bemondasokra
const Modosito = UInt8
    elolrol =  UInt8(4)
    ramondva = UInt8(2)
    hatulrol = UInt8(1)
    sehonnan = UInt8(0)

const modositoProperties = Dict([
  (elolrol,  ["Elölről",  "elolrol",  "e", "E"]),
  (ramondva, ["Rámondva", "ramondva", "r", "R"]),
  (hatulrol, ["Hátulról", "hatulrol", "h", "H"]),
  (sehonnan, [""]),
])

#Players
const Player = UInt8
    p1=Player(1) 
    p2=Player(2) 
    p3=Player(3) 
    p4=Player(4) 
    p5=Player(5) 
    p6=Player(6) 
    pX=Player(7)
    pN=Player(7)
const playerNames = Dict([
    (p1, "Alfa "),
    (p2, "Béla "),
    (p3, "Gamma"),
    (p4, "Delta"),
    (p5, "Epszi"),
    (p6, "Tétova"),
    (pX, ""),    #barmelyik jatekos (null)
    (pN, ""),    #semelyik jatekos
    ]) 

nextPlayer(pl::Player, numberOfPlayers=3) = Player(pl % numberOfPlayers + 1)
nextPlayerOffset(pl::Player, offset::Int, numberOfPlayers=3) = Player(mod(pl - 1 + offset, numberOfPlayers) + 1)
previousPlayer(pl::Player, numberOfPlayers=3) = nextPlayer(pl, -1)
# const FELVEVO = p1
# const ELLENVONAL = [p2, p3]
# const ELLENFEL1 = p2
# const ELLENFEL2 = p3


#TODO - test
const Kontra = UInt8
KE = UInt8(4)
KH = UInt8(2)

const kontraProperties = Dict([
  (KE, ["Elölről kontra",  "KE"]),
  (KH, ["Hátulról kontra", "KH"]),
])

struct KontraElement
    kontrazo::Player #pX ha kozos kontra, kulon re/mordkontranal az eredeti kontrazo van itt
    kon::Vector{Kontra} #pl. Kontrak([elolrol,elolrol,hatulrol]) az elolrol kontra, elolrol rekontra es hatulrol szub - 32x
end

struct Kontrak
    kon::Vector{KontraElement} #pl. Kontrak([elolrol,elolrol,hatulrol]) az elolrol kontra, elolrol rekontra es hatulrol szub - 32x
end

function Kontrak() 
    return Kontrak(Vector{KontraElement}())
end

function length(kontrak::Kontrak)
    return length(kontrak.kon)
end

function multiplier(kontrak::Kontrak)
    if length(kontrak) == 0
        return 1
    end
    if length(kontrak) == 1
        return prod(kontrak.kon[1].kon)
    end
    #TODO - test
    if length(kontrak) > 1
        result = [prod(ktr.kon) for ktr in kontrak.kon]
        if min(result...) == max(result...)
            return max(result...)
        end
        throw("ambigous multiplier")
    end
end

# const Kontrak = Array{Kontra, 1} #pl. Kontrak([KE,KE,KH]) az elolrol kontra, elolrol rekontra es hatulrol szub - 32x

#TODO
function show(Kontrak) end #kiirja a kontra, re, szub, mord, stb. -t

#Egy alapbemondas modositokkal
struct ContractElement
    modosito::Modosito
    bem::AlapBemondas
    kon::Kontrak
    val::Number
end

function ContractElement(suit, modosito, bem, kon, val)
    modosito = modosito == nothing ? sehonnan : modosito
    bem = bem == nothing ? semmi : bem
    kon = kon == nothing ? Kontrak() : kon
    val = val == nothing ? contractValues[(suit, bem, modosito)] * multiplier(kon) : val

    ContractElement(modosito, bem, kon, val)
end

function isequal(ce1::ContractElement, ce2::ContractElement)
    return  isequal(ce1.bem, ce2.bem) &&
            isequal(ce1.modosito, ce2.modosito) &&
            isequal(ce1.val, ce2.val) &&
            isequal(length(ce1.kon), length(ce2.kon))
end

==(ce1::ContractElement, ce2::ContractElement) = isequal(ce1::ContractElement, ce2::ContractElement)
hash(ce::ContractElement) = xor(hash(ce.bem), hash(ce.modosito), hash(ce.val), hash(ce.kon.kontrazo), hash(length(ce.kon)))
function print(io::IO, ce::ContractElement, shortFormat::Bool=true)
    print(io, 
        shortFormat ? modositoProperties[ce.modosito][end] : modositoProperties[ce.modosito][1] * " ",
        shortFormat ? alapBemondasProperties[ce.bem][2][end] : alapBemondasProperties[ce.bem][2][1] * " ")

    for kontrael in ce.kon.kon
        if kontrael.kontrazo != pN

            if !shortFormat
                print(io, playerNames[kontrael.kontrazo]); print(io, ":")
            else
                print(io, kontrael.kontrazo)
            end

            for k in kontrael.honnan
                print(io, kontraProperties[k][2])
                if !shortFormat
                    print(io, " ")
                end
            end
        end
    end
end

display(ce::ContractElement) = print(stdout, ce, false)

#A bemondas
struct Contract
    felvevo::Player
    suit::Suit
    contracts::Vector{ContractElement}
    totalvalue::Number
end

function Contract(felvevo::Player, suit::Suit, contracts::Vector{ContractElement})
    #total value is the sum of contractElements, except for csendes bemondas
    totalvalue = sum(ce.val for ce in contracts if !(ce.bem in [csendesUlti, csendesDuri]))
    #contracts sorted in canonical order: 
    #first modosito (elolrol->ramondva->hatulrol) then bemondas
    sort!(contracts, by=x->(-x.modosito, x.bem))
    return Contract(felvevo, suit, contracts, totalvalue)
end

const nocontract = Contract(pX, notrump,[],0)
isequal(c1::Contract, c2::Contract) = isequal(c1.suit, c2.suit) && isequal(c1.contracts, c2.contracts)
==(c1::Contract, c2::Contract) = isequal(c1::Contract, c2::Contract)

function copy(contract::Contract)
    #TODO: deep copy of contracts? - maybe not for performance reasons
    Contract(contract.felvevo, contract.suit, contract.contracts, contract.totalvalue)
end

@memoize function isUlti(contract::Contract)
    for ce in contract.contracts
        if ce.bem == ulti
            return true
        end
    end
    return false
end

@memoize function isRepulo(contract::Contract)
    for ce in contract.contracts
        if ce.bem == repulo
            return true
        end
    end
    return false
end

@memoize isUltiRepulo(contract::Contract) = isUlti(contract) && isRepulo(contract)

@memoize function isPartiNeeded(contract::Contract)
    if contract.suit == notrump
        return false
    end
    for ce in contract.contracts
        if ce.bem in [parti,negyvenSzaz,huszSzaz,durchmars,redurchmars,betli,rebetli,negyTizes]
            return false
        end
    end
    return true
end

@memoize function isKontra(contract::Contract)
    for ce in contract.contracts
        if length(ce.kon) > 1
            return true
        end
    end
    return false
end

@memoize function isParti(contract::Contract)
    for ce in contract.contracts
        if ce.bem == parti
            return true
        end
    end
    return false
end

@memoize function maxModosito(contract::Contract)
    result = sehonnan
    for ce in contract.contracts
        result = max(result, ce.modosito)
    end
    return result
end

contractValues = Dict{Tuple{Suit,AlapBemondas,Modosito}, Int}()
#TODO mit lehet elolrol hatulrol es ramondva bemondani
#szines bemondasok
for suit in [t, z, m, p]
    for bem in [parti, negyvenSzaz, ulti, repulo, negyAsz, durchmars, huszSzaz, rebetli, redurchmars, csendesUlti]
        for honnan in [elolrol, ramondva, hatulrol]
            contractValues[(suit, bem, honnan)] = UInt8(honnan) * suitProperties[suit][2] * alapBemondasProperties[bem][1]
        end
    end
end
#negy tizes
for suit in [t,z,m,p]
    contractValues[(suit, negyTizes, ramondva)] = 192
    contractValues[(suit, negyTizes, hatulrol)] = 55
end
#szintelen bemondasok
contractValues[(notrump, negyTizes, hatulrol)] = 55 #TODO: has to be declared and set later
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
function print(io::IO, contract::Contract, shortFormat::Bool=true)

    if contract == nocontract return "" end
    if !shortFormat
        print(io, playerNames[contract.felvevo]); print(io, ":")
        print(io, suitProperties[contract.suit][1][1], " ")
        for ce in contract.contracts
            print(io, ce, shortFormat)
        end
        print(io, " ($(contract.totalvalue))")
    else
        print(io, contract.felvevo); print(io, ":")
        print(io, suitProperties[contract.suit][1][end])
        for ce in contract.contracts
            print(io, ce, shortFormat)
        end
    end

end

display(contract::Contract) = print(stdout, contract, false)

#TODO: write test cases for this
#This will raise an ArgumentException if not OK
function validateContract(contract::Contract, player::Player=pX, previousBemondas::Contract=nocontract, stage::Modosito=sehonnan)
    
    bemondasok = [ce.bem for ce in contract.contracts]
    previousBemondasok = [ce.bem for ce in previousBemondas.contracts]

    #validity checks
    # 1. no duplicate (ulti ulti)
    if unique(bemondasok) != bemondasok
        throw(ArgumentError("dupla bemondás"))
    end
    # 2. szintelen - szines (no notrump ulti)
    if contract.suit == notrump && 
        !isempty(bemondasok ∩ [ulti, parti, repulo, negyvenSzaz, huszSzaz, negyAsz, durchmars, csendesUlti])
        throw(ArgumentError("színtelen ulti/parti/repulo/negyvenSzaz/huszSzaz/durchmars/csendesUlti"))
    end
    if contract.suit != notrump && betli in bemondasok
        throw(ArgumentError("színes betli"))
    end
    # 3. parti vs. 40s, 20s, stb.
    if parti in bemondasok && !isempty(bemondasok ∩ [negyvenSzaz, huszSzaz, durchmars, redurchmars])
        throw(ArgumentError("Parti + negyvenSzaz/huszSzaz/durchmars/redurchmars"))
    end
    # 4. 4T/betli/reduri + semmi
    if length(bemondasok) > 1 && 
        (!isempty([negyTizes, betli, rebetli, semmi] ∩ bemondasok) || 
        contract.suit == notrump && redurchmars in bemondasok)
        
        throw(ArgumentError("4 Tízes/betli/rebetli/szintelen redurchmars csak egyedül állhat"))
    end
    #5: 40-100 + 20-100 = NO
    if negyvenSzaz in bemondasok && huszSzaz in bemondasok
        throw(ArgumentError("40-100 es 20-100 nem lehet együtt"))
    end

    #6. Elolrol, ramondva, hatulrol modosito stimmeljen 
    modositok = [ce.modosito for ce in contract.contracts]
    if hatulrol in modositok && !isempty([elolrol, ramondva] ∩ modositok)
        throw(ArgumentError("Hátulról és elölről/rámondva bemondások együtt"))
    end
    if sehonnan in modositok && !isempty([elolrol, ramondva, hatulrol] ∩ modositok)
        throw(ArgumentError("Sehonnan és elölről/rámondva/hátulról bemondások együtt"))
    end
    for ce in contract.contracts
        if ce.modosito == ramondva &&
            (
                ce.bem in [parti, csendesUlti, betli, rebetli] ||
                (contract.suit == notrump && ce.bem == redurchmars)
            )
            throw(ArgumentError("Rámondva parti/csendesUlti/betli/szintelen redurchmars?"))
        end
        if ce.modosito == elolrol &&
            (
                ce.bem == negyTizes || 
                (contract.suit == notrump && ce.bem == redurchmars)
            )

            throw(ArgumentError("Elölről 4 Tízes/szintelen redurchmars?"))
        end
    end
    
    #7. Ramondas stimmeljen az elozo bemondassal
    #minden elolrol bemondas ott legyen, kiveve parti vs. 40sz 20sz, dur
    if stage == ramondva
        ramondottak = [ce.bem for ce in contract.contracts if ce.modosito == ramondva]
        @assert (player == previousBemondas.felvevo)
        for ce in contract.contracts
            if ce.modosito == elolrol && !(ce in previousBemondas.contracts)
                #parti elhagyhato ha van 40s, 20s vagy duri
                if !(ce == parti && !isempty([negyvenSzaz, huszSzaz, durchmars, redurchmars] ∩ ramondottak))
                    throw(ArgumentError("Elölről bemondás hova tűnt?"))
                end
            end
        end
    end

    # 8. Kontrak (csak azt lehet megkontrazni ami van, es ahonnan ahol vagyunk)
    if isKontra(contract)
        #make sure all bem are the same
        if bemondasok != previousBemondasok
            throw(ArgumentError("Kontránál bemondás nem tűnhet el vagy jelenhet meg"))
        end
        for i in 1:length(bemondasok)
            ce = contract.contracts[i]
            pce = previousBemondasok.contracts[i]
            if ce.modosito != pce.modosito
                throw(ArgumentError("Kontránál bemondás ugyanonnan kell hogy jöjjön (elölről, rámondvá, hátulról)"))
            end
            if length(ce.kon) < length(pce.kon)
                throw(ArgumentError("Kevesebb Kontra?"))
            elseif length(ce.kon) > length(pce.kon) + 1
                throw(ArgumentError("Dupla Kontra?"))
            elseif length(ce.kon) > length(pce.kon) #megkontrazta
                ujkontra = ce.kon.kontrazo[end]
                if stage == ramondva
                    throw(ArgumentError("rossz kontra"))
                elseif stage == elolrol && ujkontra != KE
                    throw(ArgumentError("Elölről kontra kéne ide"))
                elseif stage in [hatulrol, ramondva] && ujkontra != KH
                    throw(ArgumentError("Hátulról kontra kéne ide"))
                elseif stage == sehonnan
                    #NOP, probably just parsed
                end

                if ce.bem in [csendesUlti, csendesDuri]
                    throw(ArgumentError("Csendes Ulti/Duri kontra?"))
                end
    # 9. Sajat bemondast nem lehet kontrazni/szubkontrazni csak rekontrazni/mordkontrazni
                if  player == previousBemondas.felvevo && length(ce.kon) % 2 == 1
                    throw(ArgumentError("Saját bemondást nem lehet kontrázni/szubkontrázni csak rekontrázni/mordkontrázni"))
                end 
    # TODO: 10. Hatulrol kontrak kezelese:
    # ha a jatek elkezdodott, lehet kontrazni, felvevo mindig rekontrazhat, + szub/mord stb.

    # TODO: 11. Kulon kontrazodo bemondasok (betli, negyTizes) kezelese:
            end
        end
    end


    #11. (nem ramondott) uj bemondas nagyobb legyen mint az elozo
    if contract.totalvalue < previousBemondas.totalvalue
        throw(ArgumentError("Bemondás kisebb mint az előző"))
    end
    
    #12. ramondott uj bemondas nem kell, hogy nagyobb legyen

    # previousStage = sehonnan
    # for ce in previousBemondas.contracts
    #     previousStage = max(previousStage, ce.modosito)
    # end
    if contract.totalvalue == previousBemondas.totalvalue &&
        !(player == previousBemondas.felvevo && stage == ramondva)  #&& previousStage == elolrol

        throw(ArgumentError("Bemondás ugyanakkora mint az előző"))
    end
end

#TODO: heuristic parsing
function parseContract(contractS::AbstractString, player::Player=pX, previousBemondas::Contract=nocontract, stage::Modosito=sehonnan)
    contractS = chomp(contractS)

    if isempty(contractS) || contractS=="n" || contractS=="nocontract"
        return nocontract
    end

    playerSep = split(contractS, ":")
    @assert (length(playerSep) <= 2)

    if length(playerSep) == 2
        player = parse(Player, playerSep[1])
        contractS = playerSep[2]
    end

    contractElements = Vector{ContractElement}()
    
    #TODO: test kontrazo, kontrak
    regexp = r"(?<suit>(t|z|m|p|a|b|c|d|s|n|nt|sz)?)(?<modosito>(E|R|H)?)(?<bemondas>(Passz|Parti|semmi|Par|Ult|Rep|4A|Dur|Bet|40s|20s|4T|Tbet|Tdur|Terb|Terd|TDur|TBet|CsU|Csu|ulti|Ulti|rep|U|u|R|r)?)(?<kontrazo>([0-9])?)(?<kontrak>((pX|pN|p1|p2|p3|p4|p5|p6)?(KE|KH|k|K|Kontra|kontra|KRe|KSub|KMord))*)*\s*" #(?<value>([0-9]*)?)
    # regexp_canonical = r"(?<suit>(t|z|m|p|a|b|c|d|n|x)?)(?<modosito>(E|R|H)?)(?<bemondas>(Par|Ult|Rep|4A|Dur|Bet|40s|20s|4T|TDur|TBet|CsU)?)(?<kontrak>(KE|KH)*)\s*" #(?<value>([0-9]*)?)

    suit = nosuit #remembered between contractElements
    modosito = sehonnan #remembered between contractElements

    for mtch in eachmatch(regexp, contractS)
        #DEBUG
        # matches = collect(eachmatch(regexp, contractS))
        # mtch=matches[1]
        # println(mtch)
        #DEBUG END

        #empty string match
        if isempty(mtch.match)
            continue
        end

        for (key,val) in suitProperties
            if mtch[:suit] in val[1]
                suit = key
            end
        end
        for (key,val) in modositoProperties
            if mtch[:modosito] in val
                modosito = key
            end
        end
        bemondas = semmi #this does not carry over
        for (key,val) in alapBemondasProperties
            if mtch[:bemondas] in val[2]
                bemondas = key
            end
        end

        kontrak = Kontrak() #this does not carry over
        # TODO - one more level, double-check
        allKontrakRegexp = r"(?<player>(pX|pN|p1|p2|p3|p4|p5|p6)?)(<allKontrak>(KE|KH|k|K|Kontra|kontra|KRe|KSub|KMord)*)\s*"
        for allKontrakMatch in eachmatch(allKontrakRegexp, String(mtch[:kontrak]))
            kontraRegexp = r"(?<kontra>(KE|KH|k|K|Kontra|kontra|KRe|KSub|KMord)?)\s*"
            for kontraMatch in eachmatch(kontraRegexp, String(allKontrakMatch[:allKontrak]))
                for (key,val) in kontraProperties
                    if kontraMatch[:kontra] in val
                        push!(kontrak, key)
                    end
                end
            end
            # push!(kontrak, key)
        end            
        # value = isempty(mtch["value"]) ? nothing : parse(Int, mtch["value"])
        # ce = ContractElement(suit, modosito, bemondas, kontrak, value)

        ce = ContractElement(suit, modosito, bemondas, kontrak, nothing)
        push!(contractElements, ce)
    end

    #total value will be sum of contractElements, except for csendes bemondas
    contract = Contract(player, suit, contractElements)

    #add parti bemondas if needed - note: totalvalue does change!
    if isPartiNeeded(contract)
        extraParti = ContractElement(suit, maxModosito(contract), parti, nothing, nothing)
        push!(contract.contracts, extraParti)
        contract = Contract(contract.felvevo, contract.suit, contract.contracts)
    end

    #add csendes bemondas if needed - note: totalvalue does not change!
    if suit != notrump && !isUlti(contract)
        for ce in contract.contracts
            if ce.bem == parti
                csU = ContractElement(suit, ce.modosito, csendesUlti, nothing, nothing)
                push!(contract.contracts, csU)
                break
            end
        end
    end

    #This will raise an ArgumentException if not OK
    validateContract(contract, player, previousBemondas, stage)

    return contract
end

##############
#Tests
##############
