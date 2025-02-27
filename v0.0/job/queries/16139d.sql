SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND cn.id > 176565 AND cn.country_code IN ('[ch]', '[jo]', '[so]') AND mc.company_type_id = 2 AND cn.name_pcode_nf > 'I4242' AND t.id > 1012231 AND mc.movie_id > 2236392;