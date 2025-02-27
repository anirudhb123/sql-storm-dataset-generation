SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.md5sum LIKE '%2e%' AND k.keyword < 'stealing-boyfriend' AND mi.info < 'VEB 479,954 (Venezuela) (15 March 2009) (35 screens)' AND t.id < 1253159 AND t.series_years > '1947-1951';