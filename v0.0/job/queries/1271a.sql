SELECT min(n.name) AS member_in_charnamed_movie
FROM cast_info AS ci, company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, name AS n, title AS t
WHERE n.id = ci.person_id AND ci.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.movie_id = mc.movie_id AND ci.movie_id = mk.movie_id AND mc.movie_id = mk.movie_id
AND n.name_pcode_cf LIKE '%Y%' AND t.production_year IN (1895, 1900, 1909, 1922, 1927, 1929, 1939, 1947, 1990, 2016) AND mc.company_type_id < 2 AND ci.note IS NOT NULL;