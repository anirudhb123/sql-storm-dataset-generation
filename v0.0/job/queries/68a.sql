SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND cn.country_code IS NOT NULL AND k.keyword IN ('dog-copulation', 'drunken-employee', 'esophagus', 'gallium-scan', 'trapezium') AND mc.id > 620764 AND t.production_year IN (1918, 1948, 1958, 1969, 2001, 2009, 2012);