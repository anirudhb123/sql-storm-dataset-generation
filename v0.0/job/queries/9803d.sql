SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.production_year IN (1894, 1898, 1908, 1912, 1915, 1920, 1926, 1929, 1939, 1968) AND cn.country_code LIKE '%]%' AND t.title < 'Cut from Cardboard' AND cn.name_pcode_nf LIKE '%14%' AND cn.id < 32104 AND k.keyword LIKE '%drinking%';