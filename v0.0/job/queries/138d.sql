SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND k.phonetic_code IN ('B2454', 'B354', 'C6123', 'E456', 'G4241', 'H54', 'N23', 'O1563', 'W4313') AND t.phonetic_code LIKE '%2%' AND t.production_year < 2009 AND ci.nr_order IS NOT NULL;