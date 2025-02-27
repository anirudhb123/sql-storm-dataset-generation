SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.series_years IS NOT NULL AND t.title > 'A Whole New World' AND mk.keyword_id < 9841 AND t.md5sum < '23207ef915cfb686edf29a08a7da40f6' AND t.production_year > 2012;