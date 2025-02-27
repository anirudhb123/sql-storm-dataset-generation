SELECT min(mi_idx.info) AS rating, min(t.title) AS movie_title
FROM info_type AS it, keyword AS k, movie_info_idx AS mi_idx, movie_keyword AS mk, title AS t
WHERE t.id = mi_idx.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi_idx.movie_id AND k.id = mk.keyword_id AND it.id = mi_idx.info_type_id
AND t.title < 'Aflevering 478' AND t.season_nr IN (2006, 22, 24, 28, 40, 42, 49, 59, 69) AND t.md5sum IS NOT NULL AND k.id > 49538 AND mi_idx.info_type_id = 101;