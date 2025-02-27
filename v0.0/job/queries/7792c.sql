SELECT min(mi_idx.info) AS rating, min(t.title) AS movie_title
FROM info_type AS it, keyword AS k, movie_info_idx AS mi_idx, movie_keyword AS mk, title AS t
WHERE t.id = mi_idx.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi_idx.movie_id AND k.id = mk.keyword_id AND it.id = mi_idx.info_type_id
AND mi_idx.movie_id > 2274523 AND mi_idx.info IN ('...0.440..', '...0004201', '...1..0.16', '...1.53...', '0.0.011001', '100.001114', '11...21.14', '11..122.3.', '1112100001', '3.....1.14');