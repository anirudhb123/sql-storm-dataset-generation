SELECT min(mi_idx.info) AS rating, min(t.title) AS movie_title
FROM info_type AS it, keyword AS k, movie_info_idx AS mi_idx, movie_keyword AS mk, title AS t
WHERE t.id = mi_idx.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi_idx.movie_id AND k.id = mk.keyword_id AND it.id = mi_idx.info_type_id
AND k.phonetic_code IN ('E2626', 'G253', 'H3125', 'L413', 'O1641', 'P2312', 'P2541', 'S6136', 'T2562', 'Y654') AND t.md5sum < '8fb83860edeb68fe72ce55d6c43ed9de' AND it.id < 110;