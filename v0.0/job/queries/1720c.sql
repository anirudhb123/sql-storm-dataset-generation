SELECT min(mi_idx.info) AS rating, min(t.title) AS movie_title
FROM info_type AS it, keyword AS k, movie_info_idx AS mi_idx, movie_keyword AS mk, title AS t
WHERE t.id = mi_idx.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi_idx.movie_id AND k.id = mk.keyword_id AND it.id = mi_idx.info_type_id
AND mi_idx.movie_id IN (1264423, 1393478, 1696518, 1964325, 2455083, 2502853, 286960, 316705, 706168) AND t.production_year IS NOT NULL AND mk.id > 832512;