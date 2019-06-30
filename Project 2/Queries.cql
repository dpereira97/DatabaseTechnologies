// Query 1
MATCH(uCurr:User{id:138})-[:FRIEND_OF*2..4]->(friend:User)
WITH uCurr.nationality as paisuCurr, uCurr.age as idadeuCurr, uCurr.topico_fav as topicoCurr, uCurr.ep_fav as epCurr, uCurr.personagem_fav as personagemCurr, uCurr.personality as personalityCurr,
 uCurr.activity as activityCurr, uCurr.social as socialCurr, friend
WHERE (friend.nationality = paisuCurr AND (friend.age = idadeuCurr OR friend.age = idadeuCurr + 3)) OR 
(friend.nationality = paisuCurr AND (friend.age = idadeuCurr OR friend.age = idadeuCurr + 3) AND friend.topico_fav = topicoCurr AND friend.ep_fav = epCurr AND friend.personagem_fav = personagemCurr) OR
(friend.topico_fav = topicoCurr AND friend.ep_fav = epCurr AND friend.personagem_fav = personagemCurr) OR 
(friend.topico_fav = topicoCurr AND friend.ep_fav = epCurr AND friend.personagem_fav = personagemCurr AND friend.personality = personalityCurr AND friend.activity = activityCurr) OR 
(friend.topico_fav = topicoCurr AND friend.ep_fav = epCurr AND friend.personagem_fav = personagemCurr AND friend.personality = personalityCurr AND friend.activity = activityCurr) OR
(friend.topico_fav = topicoCurr AND friend.ep_fav = epCurr AND friend.personagem_fav = personagemCurr AND friend.personality = personalityCurr AND friend.activity = activityCurr AND friend.social = socialCurr)
RETURN friend.id
LIMIT 4


// query 2
MATCH (x:Character {actor:"Bob Saget"})-[:APPEARED_IN_EPISODE]->(ep)
MATCH (coperson:Character)-[:APPEARED_IN_EPISODE]->(ep)
WITH COLLECT(distinct coperson) as copersons
MATCH (personagem:Character)
WHERE NOT personagem in copersons
return personagem.actor

// query 3
MATCH (ep1:Episode)-[:NEXT_EPISODE*5]->(ep5)
WITH max(ep5.timestamp - ep1.timestamp) as tempoMax
MATCH (ep1:Episode)-[:NEXT_EPISODE*5]->(ep5)
WHERE (ep5.timestamp - ep1.timestamp) = tempoMax
RETURN ep1.id,ep5.id,tempoMax/86400 as dias
LIMIT 1


// query 4

MATCH(uCurr:User{id:50})-[:FRIEND_OF*1..3]->(friend:User)
WITH COUNT(*) AS maxTimes
MATCH(uCurr:User{id:50})-[:FRIEND_OF*1..3]->(friend:User)
WITH friend.topico_fav as topico, COUNT(friend.topico_fav) as times, maxTimes
WITH topico, 1.0 - (1.0 * times / maxTimes) AS peso
ORDER BY (peso) ASC
WITH head(COLLECT([topico])) as linha
UNWIND linha as topicoEscolhido
MATCH(uCurr:User{id:50})-[:FRIEND_OF*1..3]->(friend:User)
WITH friend.ep_fav as epFavAmigo, topicoEscolhido
MATCH (ep:Episode{id:epFavAmigo})-[:TOPIC]->(topic:Topic{id:topicoEscolhido})
WITH ep.viewers+(ep.ranking/10) as total, COLLECT(DISTINCT ep) as eps
UNWIND eps as episode
RETURN episode.id, episode.title
ORDER BY total DESC
LIMIT 5