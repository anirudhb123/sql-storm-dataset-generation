SELECT min(mi_idx.info) AS rating, min(t.title) AS movie_title
FROM info_type AS it, keyword AS k, movie_info_idx AS mi_idx, movie_keyword AS mk, title AS t
WHERE t.id = mi_idx.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi_idx.movie_id AND k.id = mk.keyword_id AND it.id = mi_idx.info_type_id
AND t.production_year = 1977 AND t.phonetic_code IN ('B5413', 'E2623', 'G2353', 'H3462', 'M6354', 'X5') AND k.id > 33913 AND it.info > 'LD digital sound';