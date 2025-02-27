SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.title < 'Megami ibunroku debiru sabaibâ' AND cn.name_pcode_nf > 'O1315' AND cn.md5sum < '620aea63b7957f5525ceeec0b5a82472' AND t.production_year IN (2006);