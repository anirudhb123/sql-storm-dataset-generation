SELECT min(mi_idx.info) AS rating, min(t.title) AS movie_title
FROM info_type AS it, keyword AS k, movie_info_idx AS mi_idx, movie_keyword AS mk, title AS t
WHERE t.id = mi_idx.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi_idx.movie_id AND k.id = mk.keyword_id AND it.id = mi_idx.info_type_id
AND t.season_nr IN (14, 19, 1992, 2012, 46, 59, 66, 69, 73, 91) AND mi_idx.info < '6100.1...0' AND t.id < 1360541;