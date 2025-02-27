SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND k.phonetic_code = 'V1636' AND k.keyword > 'taking-inventory' AND mi.movie_id > 736215 AND mk.movie_id < 2117296;