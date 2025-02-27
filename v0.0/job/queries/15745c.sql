SELECT min(mi_idx.info) AS rating, min(t.title) AS movie_title
FROM info_type AS it, keyword AS k, movie_info_idx AS mi_idx, movie_keyword AS mk, title AS t
WHERE t.id = mi_idx.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi_idx.movie_id AND k.id = mk.keyword_id AND it.id = mi_idx.info_type_id
AND k.phonetic_code IN ('A5435', 'B3462', 'E1253', 'E2534', 'E5326', 'F462', 'R3415', 'W5253') AND t.imdb_index IS NOT NULL AND t.phonetic_code LIKE '%3%' AND mi_idx.id > 711340 AND t.kind_id < 3;