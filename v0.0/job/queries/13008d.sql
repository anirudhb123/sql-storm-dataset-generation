SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND mk.movie_id IN (1047503, 138910, 1541534, 1685906, 1944848, 2106131, 2116879, 2117224, 2383197, 640453) AND n.imdb_index > 'CXIII';