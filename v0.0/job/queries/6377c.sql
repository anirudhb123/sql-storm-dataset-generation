SELECT min(a1.name) AS writer_pseudo_name, min(t.title) AS movie_title
FROM aka_name AS a1, cast_info AS ci, company_name AS cn, movie_companies AS mc, name AS n1, role_type AS rt, title AS t
WHERE a1.person_id = n1.id AND n1.id = ci.person_id AND ci.movie_id = t.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.role_id = rt.id AND a1.person_id = ci.person_id AND ci.movie_id = mc.movie_id
AND ci.nr_order < 1081 AND t.md5sum IN ('2464d5293ea5358737996d5414d2b04c', '2a0c3437d35e0fe8a05e8f82b1f2cb71', '38134aae22e2102a68925b57b21e396d', 'd2b8c8a261b6e18d7feefbbc75eeba3e');