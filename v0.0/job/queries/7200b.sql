SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND ci.id < 13614849 AND mk.movie_id IN (1808923, 2025919, 2116754, 2121477, 2443747, 2511026, 550519) AND ci.note IS NOT NULL AND k.phonetic_code IS NOT NULL AND n.md5sum IS NOT NULL;