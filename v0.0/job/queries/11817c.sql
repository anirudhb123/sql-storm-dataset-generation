SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND mk.movie_id IN (1083913, 1229389, 2040853, 205008, 2178126, 2204754, 2266852, 2309941, 2455001, 398914) AND t.kind_id > 0;