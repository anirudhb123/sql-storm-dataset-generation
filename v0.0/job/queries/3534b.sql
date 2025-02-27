SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.md5sum < '96e489b3e76fee3e8aac45641879248b' AND k.id > 86024 AND mi.info_type_id IN (106, 109, 11, 40, 5, 72, 78, 87, 92);