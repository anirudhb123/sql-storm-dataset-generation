SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND mi.movie_id < 490806 AND mi.id > 3163629 AND mk.keyword_id IN (117536, 130586, 51531, 77782, 79527, 7956, 8440) AND t.series_years > '1988-2007';