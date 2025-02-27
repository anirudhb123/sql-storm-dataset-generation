SELECT min(mi_idx.info) AS rating, min(t.title) AS movie_title
FROM info_type AS it, keyword AS k, movie_info_idx AS mi_idx, movie_keyword AS mk, title AS t
WHERE t.id = mi_idx.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi_idx.movie_id AND k.id = mk.keyword_id AND it.id = mi_idx.info_type_id
AND mi_idx.info < '166028' AND t.md5sum > '789b015ab315e9cf1f20cb6b3f4f8029' AND k.keyword > 'zapped-with-a-taser' AND mk.movie_id < 2107629;