SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND t.episode_nr IS NOT NULL AND n.name > 'Hilger, Mathias' AND t.episode_of_id IN (1144656, 1361154, 1472986, 1573396, 208410, 488557, 711864) AND t.title < 'My Life as a Dog';