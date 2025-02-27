SELECT min(mi_idx.info) AS rating, min(t.title) AS movie_title
FROM info_type AS it, keyword AS k, movie_info_idx AS mi_idx, movie_keyword AS mk, title AS t
WHERE t.id = mi_idx.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi_idx.movie_id AND k.id = mk.keyword_id AND it.id = mi_idx.info_type_id
AND mi_idx.info IN ('...022.2.1', '..0.001411', '..2.2111.3', '..4...1.12', '.0.0101301', '.0.0112201', '.100....07', '0.0.011320', '1.0.1.0021', '4.01.1...1');