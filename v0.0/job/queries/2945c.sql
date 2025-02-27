SELECT min(a1.name) AS writer_pseudo_name, min(t.title) AS movie_title
FROM aka_name AS a1, cast_info AS ci, company_name AS cn, movie_companies AS mc, name AS n1, role_type AS rt, title AS t
WHERE a1.person_id = n1.id AND n1.id = ci.person_id AND ci.movie_id = t.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.role_id = rt.id AND a1.person_id = ci.person_id AND ci.movie_id = mc.movie_id
AND t.imdb_index LIKE '%I%' AND a1.id < 862170 AND cn.id IN (118462, 134665, 155773, 206218, 25447, 49988, 58337, 59134, 72243, 78751) AND cn.md5sum < 'ca265dd5ed542d5f24b4178fde7ea329';