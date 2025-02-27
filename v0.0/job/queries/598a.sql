SELECT min(mi_idx.info) AS rating, min(t.title) AS movie_title
FROM info_type AS it, keyword AS k, movie_info_idx AS mi_idx, movie_keyword AS mk, title AS t
WHERE t.id = mi_idx.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi_idx.movie_id AND k.id = mk.keyword_id AND it.id = mi_idx.info_type_id
AND t.kind_id < 6 AND k.phonetic_code IS NOT NULL AND t.production_year IN (1910, 1925, 1927, 1946, 1990, 2010) AND t.md5sum < 'f048740693add26ec7c9d771896b6a10' AND it.id > 79;