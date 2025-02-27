SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.phonetic_code < 'K6' AND t.season_nr IN (1, 1988, 37, 51, 57, 60, 69) AND t.series_years IS NOT NULL;