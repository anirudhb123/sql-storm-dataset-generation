SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND cn.md5sum IS NOT NULL AND k.phonetic_code > 'F132' AND mc.company_id IN (120326, 126877, 142756, 159666, 230497, 48717, 52603, 90247, 99098, 99897);