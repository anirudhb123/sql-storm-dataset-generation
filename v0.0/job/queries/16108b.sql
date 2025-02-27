SELECT min(mi_idx.info) AS rating, min(t.title) AS movie_title
FROM info_type AS it, keyword AS k, movie_info_idx AS mi_idx, movie_keyword AS mk, title AS t
WHERE t.id = mi_idx.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi_idx.movie_id AND k.id = mk.keyword_id AND it.id = mi_idx.info_type_id
AND mi_idx.id < 859344 AND t.md5sum > 'd0d6414b4ce34c087ef3aa211c262293' AND k.keyword LIKE '%david%' AND mk.id < 1125783 AND t.phonetic_code IS NOT NULL AND mk.movie_id > 1663864;