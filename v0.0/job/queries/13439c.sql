SELECT min(a1.name) AS writer_pseudo_name, min(t.title) AS movie_title
FROM aka_name AS a1, cast_info AS ci, company_name AS cn, movie_companies AS mc, name AS n1, role_type AS rt, title AS t
WHERE a1.person_id = n1.id AND n1.id = ci.person_id AND ci.movie_id = t.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.role_id = rt.id AND a1.person_id = ci.person_id AND ci.movie_id = mc.movie_id
AND t.md5sum LIKE '%00b%' AND n1.gender LIKE '%f%' AND ci.person_role_id > 1097325 AND cn.md5sum > '0414c51ab3db4db0edc6920f8beff0fa' AND mc.note IS NOT NULL AND n1.surname_pcode LIKE '%1%';