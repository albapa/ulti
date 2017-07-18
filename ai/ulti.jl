
# module Ulti
include("ai.jl")

##############
#Engine runtime loop
##############
g = GameState(
  Contract(p, [ContractElement(elolrol, ulti, Kontrak(), 96), ContractElement(elolrol, parti, [KH], 48)], 144), #elolrol piros ulti (+ passz)
  (
    PlayerState(
      Player(1),
      CardSet([pA,pT,pK,pU,p7, mK,mU,m8, tT, z9]), #felvevo lapja
      CardSet(), UInt8(0),UInt8(0), #nincs meg utese, 20 vagy 40
    ),
    PlayerState(
      Player(2),
      CardSet([pF,p9,p8, mA,mF,m7, zK, zF, z7, tF]), #2. jatekos lapja
      CardSet(), UInt8(0),UInt8(0), #nincs meg utese, 20 vagy 40
    ),
    PlayerState(
      Player(3),
      CardSet([mT,m9, zA,zT,zU,z8, tA,tK,t8,t7 ]), #3. jatekos lapja
      CardSet(), UInt8(0),UInt8(0), #nincs meg utese, 20 vagy 40
    )
  ),
  CardSet(), #pakli ures (kiosztva)
  CardSet(), #asztal ures
  CardSet([t9, tU]), #talon
  p1 #current player
)

# g=newState(g, rand(rng, validMoves(g)))
# alfabeta(g, -1, typemin(Int), typemax(Int))
# alfabeta(g, -1, -g.contract.totalvalue, g.contract.totalvalue)

##############
#Tests
##############

# end #module
