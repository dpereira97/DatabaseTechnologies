//2.1 Quais foram os atores que nunca participaram num episódio com o ator x ?
MATCH (x:Character {actor:"Bob Saget"})-[:APPEARED_IN_EPISODE]->(ep)
MATCH (coperson:Character)-[:APPEARED_IN_EPISODE]->(ep)
WITH COLLECT(distinct coperson) as copersons
MATCH (personagem:Character)
WHERE NOT personagem in copersons
return personagem.actor

//2.2 Quantos dias demorou e qual foi o episódio que levou mais tempo a ser lançado desde que o lançamento do episódio anterior?
MATCH (ep:Episode)-[:NEXT_EPISODE]->(ep2)
WITH max(ep2.timestamp - ep.timestamp) as tempoMax
MATCH (ep:Episode)-[:NEXT_EPISODE]->(ep2)
WHERE (ep2.timestamp - ep.timestamp) = tempoMax
RETURN ep.id,ep2.id,tempoMax/86400 as dias
LIMIT 1