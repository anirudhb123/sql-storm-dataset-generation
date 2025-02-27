SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND ci.movie_id IN (1043964, 1180014, 1301388, 1316452, 1900945, 2030189, 2500400, 423471, 768098, 768616);