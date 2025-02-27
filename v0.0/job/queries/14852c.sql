SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.production_year IN (1888, 1891, 1916, 1937, 1978, 1981, 1993, 1997, 2000, 2011) AND mc.movie_id < 1859335 AND cn.name_pcode_nf < 'O6236' AND t.kind_id > 1;