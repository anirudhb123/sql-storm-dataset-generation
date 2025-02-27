SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND cn.name_pcode_sf IN ('C3412', 'I1253', 'I1416', 'I4323', 'J1452', 'L5132', 'M3535', 'P2561', 'P5256', 'T151') AND t.title > '(#4.316)' AND mk.keyword_id < 82134 AND cn.id > 34958;