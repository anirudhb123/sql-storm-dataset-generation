SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND mk.movie_id > 1858765 AND mk.keyword_id > 41100 AND k.keyword IN ('arm-splint', 'bucolic', 'dead-body-in-the-forest', 'emmanuelle', 'iris-out', 'male-female-power-struggle', 'mob-summit', 'police-partner', 'problem-film', 'sneaking-upon-someone-from-behind') AND mi.info_type_id > 103 AND t.production_year < 2004;