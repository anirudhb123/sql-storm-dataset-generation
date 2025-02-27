SELECT min(a1.name) AS writer_pseudo_name, min(t.title) AS movie_title
FROM aka_name AS a1, cast_info AS ci, company_name AS cn, movie_companies AS mc, name AS n1, role_type AS rt, title AS t
WHERE a1.person_id = n1.id AND n1.id = ci.person_id AND ci.movie_id = t.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.role_id = rt.id AND a1.person_id = ci.person_id AND ci.movie_id = mc.movie_id
AND cn.country_code IS NOT NULL AND cn.name LIKE '%Cata%' AND t.production_year IS NOT NULL AND n1.name_pcode_cf IN ('F2415', 'H1625', 'N6453', 'Q1526', 'S1562', 'V14');