// query 3 vai ser aplicada ao utilizador com id = 50

// query para devolver amigos do 50
MATCH(u:User{id:50})-[:FRIEND_OF]->(u2:User) RETURN u2
// 50 é amigo do 49, 86, 1 e 46


// OBJETIVO: query para devolver um episódio com base no topico favorito dos amigos

//Topicos favs:
// 49 - 1519
// 86 - 32652
// 1 - 24031
// 46 - 24031

MATCH(uCurr: User{id:50})
MATCH(uCurr)-[:FRIEND_OF]->(friends:User)
RETURN friends.topico_fav

// Este devovle lista com primeiro elmento o topico fav do 50 e o outro o do amigo [ERRADO]
MATCH(uCurr: User{id:50})
MATCH p = (uCurr)-[:FRIEND_OF]->(friends:User)
RETURN extract(n IN nodes(p)| n.topico_fav) AS extracted

// Esta certo, este devolve uma lista com os topicos favoritos dos amigos todos
MATCH(uCurr: User{id:50})
RETURN [(uCurr)-->(friends) WHERE friends:User | friends.topico_fav] AS topicos


// Outra tentativa
MATCH(uCurr: User{id:50})-[:FRIEND_OF]->(friends:User)
RETURN friends.topico_fav, COUNT(friends.topico_fav)

// Mais uma [CERTO!! -> DEVOLVE O NUMERO DE CONTAGEM DO TOPICO MAIS ABUNDANTE NOS AMIGOS]
// mas falta o id do topico associado ao max~
MATCH(uCurr: User{id:50})-[:FRIEND_OF]->(friends:User)
WITH friends.topico_fav as topico, COUNT(friends.topico_fav) as contagem
RETURN MAX(contagem)


// FUNCIONA! devolve topico mais comum entre amigos e a sua contagem
MATCH(uCurr: User{id:50})-[:FRIEND_OF]->(friends:User)
WITH friends.topico_fav as topico, COUNT(friends.topico_fav) as contagem
ORDER BY contagem DESC
RETURN head(COLLECT([topico, contagem]))


// Devolve apenas o tópico mais gostado pelos amigos
MATCH(uCurr: User{id:50})-[:FRIEND_OF]->(friends:User)
WITH friends.topico_fav as topico, COUNT(friends.topico_fav) as contagem
ORDER BY contagem DESC
RETURN head(COLLECT([topico]))

//Devolve 5 episodios com base no topico favorito dos amigos
MATCH(uCurr: User{id:50})-[:FRIEND_OF]->(friends:User)
WITH friends.topico_fav as topico, COUNT(friends.topico_fav) as contagem
ORDER BY contagem DESC
WITH head(COLLECT([topico])) as linha
UNWIND linha as x
MATCH (ep: Episode)-[:TOPIC]->(topicoObj:Topic{id:x})
RETURN ep.id, ep.title
LIMIT 5

// Devolver os amigos dos amigos do 50
MATCH(uCurr:User{id:50})-[:FRIEND_OF]->(friend:User)-[:FRIEND_OF]->(foaf:User) 
RETURN foaf.id as amigoDoAmigo

// Devolver os amigos dos amigos dos amigos do 50
MATCH(uCurr:User{id:50})-[:FRIEND_OF]->(friend:User)-[:FRIEND_OF]->(foaf:User)-[:FRIEND_OF]->(foafoaf:User) 
RETURN foafoaf.id as amigoDoAmigoDoAmigo


// Mostra a tabela com as contagens dos amigos dos amigos
MATCH(uCurr:User{id:50})-[:FRIEND_OF]->(friend:User)-[:FRIEND_OF]->(foaf:User)
RETURN foaf.topico_fav as topico, COUNT(foaf.topico_fav) as contagemFoaf
ORDER BY contagemFoaf DESC

// Devolve os 5 episodios com base no topico favorito dos amigos e dos amigos dos amigos
MATCH(uCurr:User{id:50})-[:FRIEND_OF]->(friend:User)
WITH friend.topico_fav as topico, COUNT(friend.topico_fav) as contagemFriend 
ORDER BY contagemFriend DESC 
MATCH(friend:User)-[:FRIEND_OF]->(foaf:User)
WITH foaf.topico_fav as topico, COUNT(foaf.topico_fav) as contagemFoaf
ORDER BY contagemFoaf DESC
WITH head(COLLECT([topico])) as linha
UNWIND linha as x
MATCH (ep: Episode)-[:TOPIC]->(topicoObj:Topic{id:x})
RETURN ep.id, ep.title
LIMIT 5

// ----------------------------------------------------------------------------------------------------------------
// Mostra a tabela com as contagens dos amigos e amigos dos amigos [NAO FUNCIONA]
MATCH(uCurr:User{id:50})-[:FRIEND_OF]->(friend:User)
RETURN friend.topico_fav as topico, COUNT(friend.topico_fav) as contagem 
UNION ALL
MATCH(uCurr:User{id:50})-[:FRIEND_OF]->(friend:User)-[:FRIEND_OF]->(foaf:User)
WITH foaf.topico_fav as topico, COUNT(foaf.topico_fav) as contagem
ORDER BY contagem DESC
RETURN topico, SUM(contagem) as contagem

// a partir de AQUI:

// pesos amigos e amigos de amigos [FUNCA mas devolve todos - queremos um MERGE dos ids]
MATCH(uCurr:User{id:50})-[:FRIEND_OF]->(friend:User)
WITH COUNT(*) AS maxTimes
MATCH(uCurr:User{id:50})-[:FRIEND_OF]->(friend:User)
WITH friend.topico_fav as topico, COUNT(friend.topico_fav) as times, maxTimes
RETURN topico, 1.0 - (1.0 * times / maxTimes) AS peso
UNION ALL 
MATCH(uCurr:User{id:50})-[:FRIEND_OF]->(friend:User)-[:FRIEND_OF]->(foaf:User)
WITH COUNT(*) AS maxTimes
MATCH(uCurr:User{id:50})-[:FRIEND_OF]->(friend:User)-[:FRIEND_OF]->(foaf:User)
WITH foaf.topico_fav as topico, COUNT(foaf.topico_fav) as times, maxTimes
RETURN topico, 1.0 - (1.0 * times / maxTimes) AS peso

// buscar eps favs dos amigos e dos amigos dos amigos do topico elegido (na query anterior - falta associar), 
// Isto devolve (separadamente) os eps com o peso calculado, falta juntar e selecionar os melhores 5
MATCH(uCurr:User{id:50})-[:FRIEND_OF]->(friend:User)
WITH friend.ep_fav as epFavAmigo
MATCH (ep:Episode{id:epFavAmigo})
WITH ep.viewers as vistas, ep.ranking as ranking
RETURN vistas+(ranking/10) as total
ORDER BY total DESC

MATCH(uCurr:User{id:50})-[:FRIEND_OF]->(friend:User)-[:FRIEND_OF]->(foaf:User)
WITH foaf.ep_fav as epFavAmigoDoAmigo
MATCH (ep:Episode{id:epFavAmigoDoAmigo})
WITH ep.viewers as vistas, ep.ranking as ranking
RETURN vistas+(ranking/10) as total
ORDER BY total DESC
    
// ----------------------------------------------------------------------------------------------------------------

// Recomendação de 5 episódios baseada num algoritmo de recomendação com os tópicos favoritos de amizade com profundidade 3
// Os episodios são recomendados com base nas visualizações e no ranking dos mesmos
// QUERY FINAL!!:

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