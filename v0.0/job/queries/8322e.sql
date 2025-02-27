SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND ci.person_id > 3282606 AND ci.role_id IN (1, 10, 11, 2, 3, 4, 5, 6, 7, 8) AND k.id < 39368 AND ci.id < 32130600 AND n.imdb_index IS NOT NULL AND t.kind_id < 4;