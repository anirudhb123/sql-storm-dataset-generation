SELECT min(mi_idx.info) AS rating, min(t.title) AS movie_title
FROM info_type AS it, keyword AS k, movie_info_idx AS mi_idx, movie_keyword AS mk, title AS t
WHERE t.id = mi_idx.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi_idx.movie_id AND k.id = mk.keyword_id AND it.id = mi_idx.info_type_id
AND t.production_year IS NOT NULL AND mi_idx.info > '29925' AND t.md5sum < '721cadc0a3b87b5e7c0674fb84b4a773' AND mk.keyword_id < 126655;