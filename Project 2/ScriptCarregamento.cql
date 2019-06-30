// Apagar BD
MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n,r

LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/mneedham/neo4j-himym/master/data/import/episodes_full.csv" AS row
MERGE (episode:Episode {id: toint(row.NumberOverall)})
ON CREATE SET episode.title = row.Title,
              episode.viewers = toFloat(row.Viewers),
              episode.dateAired = row.DateAired,
              episode.timestamp = toint(row.Timestamp),
              episode.number = toint(row.NumberInSeason),
              episode.season = toint(row.Season),
              episode.ranking = toint(row.Rating)

// Relacao entre episodio e season
MATCH (episode:Episode)
MERGE (season:Season {number: episode.season})
MERGE (episode)-[:IN_SEASON]->(season)

// Relacao next episode
MATCH (episode:Episode)
WITH episode
ORDER BY episode.id
WITH COLLECT(episode) AS episodes
FOREACH(i in RANGE(0, length(episodes)-2) |
FOREACH(n1 in [episodes[i]] | FOREACH(n2 in [episodes[i+1]] |
    MERGE (n1)-[:NEXT_EPISODE]->(n2))))

// load Personagens e ligação com episódio em que apareceu
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/mneedham/neo4j-himym/master/data/import/characters.csv" AS row
MATCH (episode:Episode {id: toint(row.EpisodeId)})
MERGE (character:Character {name: row.Character})
MERGE (character)-[:APPEARED_IN_EPISODE]->(episode)
ON CREATE SET character.actor = row.Actor

//Topics
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/mneedham/neo4j-himym/master/data/import/topics.csv" AS row
MERGE (topic:Topic {id: toint(row.TopicId)})
ON CREATE SET topic.value = row.Topic

LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/mneedham/neo4j-himym/master/data/import/topics.csv" AS row
MATCH (topic:Topic {id: toint(row.TopicId)})
MATCH (episode:Episode {id: toint(row.EpisodeId)})
MERGE (episode)-[:TOPIC {score: TOFLOAT(row.Score)}]->(topic)

// USER

LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/DPer97/Projeto2TBD/master/data/Users.csv"AS row
CREATE (user:User {id: toInteger(row.userID), nationality: row.nationality, social: row.social, relationship: row.relationship, kids: row.kids, age: toInteger(row.age), personality: row.personality, activity: row.activity, personagem_fav:toInteger(row.personagem_fav), ep_fav: toInteger(row.ep_fav), topico_fav: toInteger(row.topico_fav)})

// Relacao gosta de ep
MATCH(user:User)
MERGE(episode:Episode {id: user.ep_fav})
MERGE(user)-[:LIKES_EPISODE]->(episode)

// Relacao tem interesse em topico
MATCH(user:User)
MERGE(topic:Topic{id: user.topico_fav})
MERGE(user)-[:HAS_INTEREST]->(topic)

// AMIZADES

LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/DPer97/Projeto2TBD/master/data/amizades.csv" AS row
MATCH(user:User{id: toInteger(row.id1)})
MATCH(friend:User{id: toInteger(row.id2)})
MERGE(user)-[:FRIEND_OF]->(friend)