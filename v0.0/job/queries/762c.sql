SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.kind_id = 7 AND t.production_year IS NOT NULL AND mk.id IN (140591, 1776029, 2031630, 2155957, 4058144);