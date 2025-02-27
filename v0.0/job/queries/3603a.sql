SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND k.phonetic_code IN ('D5363', 'H5454', 'I2456', 'M4315', 'N3542', 'R1235', 'R1321', 'S1265', 'T6515') AND ci.id > 6950446 AND t.production_year IN (1922, 1925, 1955, 1961, 1970, 1972, 1980);