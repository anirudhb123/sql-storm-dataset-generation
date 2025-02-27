SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND mi.movie_id IN (1231741, 1268091, 1939997, 1946515, 2255915, 316537, 317767, 628023) AND mk.keyword_id < 122368 AND mi.note < 'zwonulldreifünfsieben filme';