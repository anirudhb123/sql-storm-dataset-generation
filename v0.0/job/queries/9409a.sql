SELECT min(mi_idx.info) AS rating, min(t.title) AS movie_title
FROM info_type AS it, keyword AS k, movie_info_idx AS mi_idx, movie_keyword AS mk, title AS t
WHERE t.id = mi_idx.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi_idx.movie_id AND k.id = mk.keyword_id AND it.id = mi_idx.info_type_id
AND k.id < 101032 AND mi_idx.id < 251716 AND k.phonetic_code IN ('D4352', 'K3212', 'L1563', 'M1362', 'M5312', 'N6245', 'R3264', 'S6531', 'W3635');