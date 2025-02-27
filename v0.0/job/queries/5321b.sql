SELECT min(a1.name) AS writer_pseudo_name, min(t.title) AS movie_title
FROM aka_name AS a1, cast_info AS ci, company_name AS cn, movie_companies AS mc, name AS n1, role_type AS rt, title AS t
WHERE a1.person_id = n1.id AND n1.id = ci.person_id AND ci.movie_id = t.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.role_id = rt.id AND a1.person_id = ci.person_id AND ci.movie_id = mc.movie_id
AND cn.md5sum LIKE '%a58c71deed7bab10aa%' AND rt.role IN ('miscellaneous crew', 'producer') AND t.md5sum > 'a23dcaf3a91252b7c7bfdcb18045eeae' AND cn.name_pcode_nf < 'I2413' AND a1.md5sum IS NOT NULL;