SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND cn.name_pcode_nf IN ('D2146', 'D2345', 'L643', 'M1414', 'N3251', 'O1423', 'P4543', 'W341') AND mc.company_id > 54508 AND mk.keyword_id > 20013;