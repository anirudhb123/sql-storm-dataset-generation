SELECT min(mi_idx.info) AS rating, min(t.title) AS movie_title
FROM info_type AS it, keyword AS k, movie_info_idx AS mi_idx, movie_keyword AS mk, title AS t
WHERE t.id = mi_idx.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi_idx.movie_id AND k.id = mk.keyword_id AND it.id = mi_idx.info_type_id
AND mk.movie_id IN (1850159, 1924864, 1970337, 2349626, 2397522, 2434870, 2455794, 598653) AND t.production_year IS NOT NULL AND mk.keyword_id < 48565 AND mi_idx.info_type_id IN (99) AND k.phonetic_code > 'O3216';