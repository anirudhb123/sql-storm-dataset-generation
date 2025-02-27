SELECT min(mi_idx.info) AS rating, min(t.title) AS movie_title
FROM info_type AS it, keyword AS k, movie_info_idx AS mi_idx, movie_keyword AS mk, title AS t
WHERE t.id = mi_idx.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi_idx.movie_id AND k.id = mk.keyword_id AND it.id = mi_idx.info_type_id
AND mk.id < 2172395 AND t.phonetic_code IN ('C1424', 'D4145', 'E6363', 'F3431', 'F631', 'J123', 'J1543', 'K2326', 'T214');