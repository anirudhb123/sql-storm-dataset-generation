SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND t.title > '(1964-08-10)' AND n.gender IS NOT NULL AND mk.movie_id IN (1698418, 1715971, 1821394, 1956149, 2008678, 2077434, 2428994, 2450794, 977976) AND t.kind_id > 4;