SELECT min(a1.name) AS writer_pseudo_name, min(t.title) AS movie_title
FROM aka_name AS a1, cast_info AS ci, company_name AS cn, movie_companies AS mc, name AS n1, role_type AS rt, title AS t
WHERE a1.person_id = n1.id AND n1.id = ci.person_id AND ci.movie_id = t.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.role_id = rt.id AND a1.person_id = ci.person_id AND ci.movie_id = mc.movie_id
AND cn.name_pcode_nf IN ('B1612', 'I6246', 'L1313', 'M2564', 'P4', 'S15', 'S6236') AND t.md5sum < '36024a990a10bdb67042dd30e1389310' AND t.production_year IS NOT NULL;