SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.series_years > '2006-2010' AND t.phonetic_code IN ('F6523', 'G34', 'I5434', 'K6131', 'N4', 'P3465', 'P3525', 'W6454', 'X463', 'Z4152');