SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND mc.company_id < 201745 AND cn.country_code IS NOT NULL AND cn.name_pcode_nf > 'T2312' AND t.id < 466163 AND t.kind_id > 1;