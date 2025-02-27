SELECT min(mi_idx.info) AS rating, min(t.title) AS movie_title
FROM info_type AS it, keyword AS k, movie_info_idx AS mi_idx, movie_keyword AS mk, title AS t
WHERE t.id = mi_idx.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi_idx.movie_id AND k.id = mk.keyword_id AND it.id = mi_idx.info_type_id
AND mi_idx.movie_id > 1392411 AND mk.keyword_id IN (110248, 111206, 115098, 131487, 39276, 76952, 84089, 9032, 93832) AND t.id > 2116640 AND t.phonetic_code IS NOT NULL AND mi_idx.info_type_id IN (99) AND t.title < 'Zwemmer uit liefde';