SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND ci.role_id IN (10, 2, 4, 5, 6, 7, 9) AND n.surname_pcode > 'M414' AND t.phonetic_code IN ('D2123', 'D563', 'E653', 'K2341', 'S2325', 'Y6216');