SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND cn.name_pcode_nf IN ('C2526', 'H1254', 'N6234', 'O5425', 'Q2161', 'V436', 'W2521') AND t.phonetic_code < 'X2123' AND cn.name > 'NTC Corporation';