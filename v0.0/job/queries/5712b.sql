SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND mi.info_type_id > 63 AND t.kind_id IN (0, 7) AND mk.keyword_id IN (115952, 1194, 120624, 133630, 19908, 2823, 31276, 56033, 69318, 87903);