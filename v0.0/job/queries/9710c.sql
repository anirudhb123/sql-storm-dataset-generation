SELECT min(a1.name) AS writer_pseudo_name, min(t.title) AS movie_title
FROM aka_name AS a1, cast_info AS ci, company_name AS cn, movie_companies AS mc, name AS n1, role_type AS rt, title AS t
WHERE a1.person_id = n1.id AND n1.id = ci.person_id AND ci.movie_id = t.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.role_id = rt.id AND a1.person_id = ci.person_id AND ci.movie_id = mc.movie_id
AND cn.md5sum IN ('5267fcbedfed0fe467cdfe3cfe6c6d13', 'a7d2d770c1ec961e5f4f6a81c36bfdff', 'aa829de6b1afbfd4a35bcb7bb1930d63', 'bffbf1bd9af32934f3889aa467c460d2');