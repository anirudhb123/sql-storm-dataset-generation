SELECT min(mi_idx.info) AS rating, min(t.title) AS movie_title
FROM info_type AS it, keyword AS k, movie_info_idx AS mi_idx, movie_keyword AS mk, title AS t
WHERE t.id = mi_idx.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi_idx.movie_id AND k.id = mk.keyword_id AND it.id = mi_idx.info_type_id
AND mi_idx.info IN ('...2111122', '.2.0011..1', '.51....1.1', '0..0.3.012', '00..003120', '00..1..114', '00.0200020', '1....03012', '1.1....5.2', '3....1.113');