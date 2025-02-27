SELECT min(mi_idx.info) AS rating, min(t.title) AS northern_dark_movie
FROM info_type AS it1, info_type AS it2, keyword AS k, kind_type AS kt, movie_info AS mi, movie_info_idx AS mi_idx, movie_keyword AS mk, title AS t
WHERE kt.id = t.kind_id AND t.id = mi.movie_id AND t.id = mk.movie_id AND t.id = mi_idx.movie_id AND mk.movie_id = mi.movie_id AND mk.movie_id = mi_idx.movie_id AND mi.movie_id = mi_idx.movie_id AND k.id = mk.keyword_id AND it1.id = mi.info_type_id AND it2.id = mi_idx.info_type_id
AND it1.id IN (13, 83, 99) AND mk.keyword_id IN (112055, 42560, 6035, 64670, 6492, 75168, 91029);