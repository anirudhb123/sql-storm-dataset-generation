SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND k.phonetic_code IN ('B4251', 'C2563', 'I5235', 'L6453', 'N6216', 'R4165', 'T6142', 'V4614', 'W4123') AND ci.nr_order = 123 AND k.id > 3168;