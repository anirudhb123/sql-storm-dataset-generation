SELECT min(a1.name) AS writer_pseudo_name, min(t.title) AS movie_title
FROM aka_name AS a1, cast_info AS ci, company_name AS cn, movie_companies AS mc, name AS n1, role_type AS rt, title AS t
WHERE a1.person_id = n1.id AND n1.id = ci.person_id AND ci.movie_id = t.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.role_id = rt.id AND a1.person_id = ci.person_id AND ci.movie_id = mc.movie_id
AND n1.name_pcode_cf < 'B6352' AND t.season_nr IN (11, 2011, 35, 4, 54, 74) AND n1.name_pcode_nf > 'U3436' AND ci.person_role_id < 2848921 AND t.id > 253896;