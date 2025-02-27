SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.production_year IN (1893, 1908, 1915, 1920, 1941, 1954, 1961, 1964, 2012, 2017) AND mc.company_id > 157119 AND k.keyword > 'year-2144';