SELECT min(mi_idx.info) AS rating, min(t.title) AS movie_title
FROM info_type AS it, keyword AS k, movie_info_idx AS mi_idx, movie_keyword AS mk, title AS t
WHERE t.id = mi_idx.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi_idx.movie_id AND k.id = mk.keyword_id AND it.id = mi_idx.info_type_id
AND t.production_year IN (1890, 1903, 1908, 1933, 1988, 2001) AND mi_idx.info LIKE '%100..1%' AND mi_idx.info_type_id IN (100, 101, 112, 113, 99);