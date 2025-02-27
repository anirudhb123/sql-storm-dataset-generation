SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND t.production_year IS NOT NULL AND t.kind_id = 2 AND n.name_pcode_cf IN ('A3416', 'B51', 'I5156', 'J4525', 'K264', 'O515', 'Q2353', 'R3561', 'V3653', 'Z5251') AND ci.movie_id > 989580 AND k.keyword < 'corinthian';