SELECT min(mi_idx.info) AS rating, min(t.title) AS movie_title
FROM info_type AS it, keyword AS k, movie_info_idx AS mi_idx, movie_keyword AS mk, title AS t
WHERE t.id = mi_idx.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi_idx.movie_id AND k.id = mk.keyword_id AND it.id = mi_idx.info_type_id
AND it.id > 72 AND k.phonetic_code > 'B3415' AND mi_idx.info_type_id = 100 AND mi_idx.id IN (1370788, 280977, 402421, 433284, 767014, 842837, 975537);