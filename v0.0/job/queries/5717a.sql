SELECT min(a1.name) AS writer_pseudo_name, min(t.title) AS movie_title
FROM aka_name AS a1, cast_info AS ci, company_name AS cn, movie_companies AS mc, name AS n1, role_type AS rt, title AS t
WHERE a1.person_id = n1.id AND n1.id = ci.person_id AND ci.movie_id = t.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.role_id = rt.id AND a1.person_id = ci.person_id AND ci.movie_id = mc.movie_id
AND n1.name_pcode_nf IN ('A465', 'D6236', 'F6314', 'H3214', 'L3542', 'O1253', 'O2414', 'Q4616', 'R3412', 'T6542') AND ci.id < 11749483 AND ci.person_id < 3529516;