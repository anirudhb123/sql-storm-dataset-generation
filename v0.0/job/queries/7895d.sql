SELECT min(a1.name) AS writer_pseudo_name, min(t.title) AS movie_title
FROM aka_name AS a1, cast_info AS ci, company_name AS cn, movie_companies AS mc, name AS n1, role_type AS rt, title AS t
WHERE a1.person_id = n1.id AND n1.id = ci.person_id AND ci.movie_id = t.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.role_id = rt.id AND a1.person_id = ci.person_id AND ci.movie_id = mc.movie_id
AND n1.name_pcode_nf IS NOT NULL AND cn.name_pcode_sf IN ('C453', 'D1524', 'E312', 'H3145', 'I2141', 'K2642', 'K4365', 'K5462', 'O2642', 'Z1645') AND t.kind_id < 7;