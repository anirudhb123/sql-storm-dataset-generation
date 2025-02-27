SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND t.title < 'Kærlighed på film' AND mk.keyword_id > 37712 AND n.id < 1760001 AND t.md5sum > '0e1e1390f50f1ea975e5c1c290a54471';