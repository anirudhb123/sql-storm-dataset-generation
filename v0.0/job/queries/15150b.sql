SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND mi.movie_id IN (1070926, 1203214, 1365975, 179492, 1927456, 2093601, 2271600, 2299857, 2429893, 909503);