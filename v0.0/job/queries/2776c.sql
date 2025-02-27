SELECT min(mi_idx.info) AS rating, min(t.title) AS movie_title
FROM info_type AS it, keyword AS k, movie_info_idx AS mi_idx, movie_keyword AS mk, title AS t
WHERE t.id = mi_idx.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi_idx.movie_id AND k.id = mk.keyword_id AND it.id = mi_idx.info_type_id
AND t.md5sum > '206d882173999437ad4cb625fa4115a6' AND mk.movie_id IN (1845680, 1908893, 1913653, 2017276, 2086492, 219360, 2240725, 2267267, 47392, 920486) AND k.id > 31024;