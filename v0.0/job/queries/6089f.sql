SELECT min(n.name) AS member_in_charnamed_movie
FROM cast_info AS ci, company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, name AS n, title AS t
WHERE n.id = ci.person_id AND ci.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.movie_id = mc.movie_id AND ci.movie_id = mk.movie_id AND mc.movie_id = mk.movie_id
AND t.kind_id < 7 AND cn.name_pcode_sf > 'R5361' AND t.phonetic_code < 'Z5163' AND t.production_year IN (1923, 1937, 1941, 1954, 1959, 1960, 1982, 2004, 2005, 2012);