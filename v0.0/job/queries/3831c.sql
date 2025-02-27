SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND k.id < 15243 AND t.phonetic_code IN ('A246', 'A5145', 'C2646', 'D1343', 'G235', 'H3626', 'I2532', 'I514', 'Q3413', 'V5156') AND t.production_year = 1960;