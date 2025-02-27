SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND ci.person_id < 625894 AND t.phonetic_code LIKE '%P461%' AND n.imdb_index IS NOT NULL AND ci.movie_id < 907452 AND mk.movie_id < 1898279 AND mk.id < 3294773 AND ci.role_id > 9;