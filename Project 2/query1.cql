//query 1 vai ser aplicada ao utlizador com id= 138
// Lógica: 
//   -> mesmo pais e idade ou mais 3 anos de idade
//   -> mesmo pais, idade, personagem fav, ep fav, topico fav
//   -> mesmo topico, ep, personagem
//   -> mesmo topico fav, ep fav, personagem fav, personalidade, actividade
//   -> mesmo topico fav, mesmo ep fav, mesma personagem fav, mesma personalidade, mesmo activity e mesmo social

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