SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.production_year IN (1889, 1893, 1924, 1955, 1985, 1989, 1993, 2013, 2017) AND t.kind_id = 4 AND mc.company_type_id = 2 AND mc.movie_id < 1902585;