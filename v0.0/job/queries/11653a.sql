SELECT min(mi_idx.info) AS rating, min(t.title) AS movie_title
FROM info_type AS it, keyword AS k, movie_info_idx AS mi_idx, movie_keyword AS mk, title AS t
WHERE t.id = mi_idx.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi_idx.movie_id AND k.id = mk.keyword_id AND it.id = mi_idx.info_type_id
AND t.md5sum IS NOT NULL AND mi_idx.info_type_id < 112 AND k.id < 57946 AND it.id > 98 AND mi_idx.info < '2192' AND t.series_years LIKE '%1966%';