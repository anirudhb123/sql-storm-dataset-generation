SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND cn.name_pcode_sf < 'T1262' AND mk.id IN (2170857, 218689, 2779937, 3410480, 3544337) AND cn.name_pcode_nf < 'K3421' AND mc.company_type_id = 1;