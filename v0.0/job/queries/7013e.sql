SELECT min(n.name) AS member_in_charnamed_movie
FROM cast_info AS ci, company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, name AS n, title AS t
WHERE n.id = ci.person_id AND ci.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.movie_id = mc.movie_id AND ci.movie_id = mk.movie_id AND mc.movie_id = mk.movie_id
AND ci.id > 29777604 AND k.phonetic_code IN ('C1341', 'E3616', 'E6152', 'F3623', 'P652', 'Q3632') AND mk.id > 1176907 AND mc.company_type_id = 1 AND ci.person_id > 3511135;