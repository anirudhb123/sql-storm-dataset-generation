SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND t.episode_of_id < 878019 AND k.id IN (115490, 116349, 121425, 133905, 15629, 39012, 71208, 7753, 82926) AND n.imdb_index LIKE '%XX%' AND ci.person_id < 3715008;