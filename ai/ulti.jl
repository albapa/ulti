
# module Ulti
include("ai.jl")

##############
#Engine runtime loop
##############
g = GameState(
  Contract(p, [ContractElement(elolrol, ulti, [], 96), ContractElement(elolrol, parti, [], 24)], 120), #elolrol piros ulti (+ passz)
  CardSet(), #pakli ures (kiosztva)
  Array{Card, 1}(), #asztal ures
  CardSet([t9, tU]), #talon
  [
    PlayerState(
      Player(1),
      CardSet([pA,pT,pK,pU,p7, mK,mU,m8, tT, z9]), #felvevo lapja
      [], 0,0, #nincs meg utese, 20 vagy 40
    ),
    PlayerState(
      Player(2),
      CardSet([pF,p9,p8, mA,mF,m7, zK, zF, z7, tF]), #2. jatekos lapja
      [], 0,0, #nincs meg utese, 20 vagy 40
    ),
    PlayerState(
      Player(3),
      CardSet([mT,m9, zA,zT,zU,z8, tA,tK,t8,t7 ]), #3. jatekos lapja
      [], 0,0, #nincs meg utese, 20 vagy 40
    )
  ],
  p1 #current player
)

##############
#Tests
##############

# end #module
