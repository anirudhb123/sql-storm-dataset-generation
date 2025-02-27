SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND cn.name_pcode_nf > 'A645' AND mk.movie_id IN (1054452, 1185255, 1452447, 1756790, 2098538, 2160443, 2216774, 2309479, 316332);