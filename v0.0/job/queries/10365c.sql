SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND k.phonetic_code > 'V3252' AND t.production_year IN (1889, 1896, 1948, 1952, 1963, 1970, 1979, 1990, 2007, 2013);