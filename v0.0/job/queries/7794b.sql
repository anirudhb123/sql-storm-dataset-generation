SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND ci.nr_order IS NOT NULL AND k.phonetic_code > 'M3161' AND t.phonetic_code IN ('I3461', 'J6235', 'R4546', 'T1345', 'W6523') AND t.production_year < 1929;