SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND k.phonetic_code IN ('C3236', 'E5651', 'G3632', 'G4263', 'J2151', 'J525', 'J6531', 'O3465', 'S1231', 'S3251') AND n.name_pcode_nf IS NOT NULL AND mk.movie_id > 2181625;