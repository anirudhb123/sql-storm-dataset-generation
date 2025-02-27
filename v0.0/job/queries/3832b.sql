SELECT min(mi_idx.info) AS rating, min(t.title) AS movie_title
FROM info_type AS it, keyword AS k, movie_info_idx AS mi_idx, movie_keyword AS mk, title AS t
WHERE t.id = mi_idx.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi_idx.movie_id AND k.id = mk.keyword_id AND it.id = mi_idx.info_type_id
AND mi_idx.info > '1111121..1' AND mk.keyword_id IN (111247, 32714, 38988, 41042, 538, 87637) AND t.season_nr < 45 AND t.id < 1883036;