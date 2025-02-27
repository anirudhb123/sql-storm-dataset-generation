SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.production_year > 1908 AND t.md5sum < 'f273249d3e36ee6c89b2948e57eb6ee5' AND k.keyword = 'show-choir';