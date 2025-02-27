SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.production_year IN (1925, 1930, 1960, 1962, 1978, 1998, 2011) AND k.id < 73997 AND cn.id IN (17464) AND cn.country_code IS NOT NULL;