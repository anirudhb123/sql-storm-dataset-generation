SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND mk.id < 2990187 AND t.md5sum IS NOT NULL AND mi.info_type_id > 5 AND t.title < 'El meteorito de las 10:15';