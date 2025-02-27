SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.production_year IN (1880, 1894, 1908, 1915, 1923, 1930, 1944, 1958, 1983, 2009) AND k.id < 23367;