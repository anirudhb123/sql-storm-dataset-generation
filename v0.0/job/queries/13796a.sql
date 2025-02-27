SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND cn.id < 191065 AND t.production_year IN (1925, 1938, 1939, 1941, 1954, 1973, 1976, 1993, 1995, 2014) AND mc.company_type_id = 1 AND t.title > 'Rires et pleurs' AND mc.movie_id > 636550;