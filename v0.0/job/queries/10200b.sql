SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND mi.movie_id IN (1793411, 1860961, 2017523, 2091059, 2404815, 279791, 307525, 50156, 814528, 963348);