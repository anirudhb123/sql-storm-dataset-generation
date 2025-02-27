SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND mc.movie_id IN (1464265, 1707647, 1761148, 185239, 1968342, 2092719, 2348865, 304306, 506823) AND cn.name_pcode_nf LIKE '%52%';