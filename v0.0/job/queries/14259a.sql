SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.kind_id IN (0, 2, 4, 6, 7) AND k.keyword < 'death-of-policeman' AND t.series_years < '1960-1990' AND t.season_nr < 9 AND k.id > 26960;