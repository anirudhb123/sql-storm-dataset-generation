SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND mk.movie_id < 2276133 AND t.series_years LIKE '%1993%' AND t.title < 'Kuroi chibusa' AND t.md5sum IS NOT NULL;