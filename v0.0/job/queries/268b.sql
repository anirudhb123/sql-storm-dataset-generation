SELECT min(mi_idx.info) AS rating, min(t.title) AS movie_title
FROM info_type AS it, keyword AS k, movie_info_idx AS mi_idx, movie_keyword AS mk, title AS t
WHERE t.id = mi_idx.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi_idx.movie_id AND k.id = mk.keyword_id AND it.id = mi_idx.info_type_id
AND mk.id < 3218377 AND t.production_year IN (2006) AND t.md5sum < 'fc90ef14d0406fd8db5ed2416dd99fdb' AND t.imdb_index IN ('II', 'XVI');