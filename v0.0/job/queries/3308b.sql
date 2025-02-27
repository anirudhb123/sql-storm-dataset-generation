SELECT min(a1.name) AS writer_pseudo_name, min(t.title) AS movie_title
FROM aka_name AS a1, cast_info AS ci, company_name AS cn, movie_companies AS mc, name AS n1, role_type AS rt, title AS t
WHERE a1.person_id = n1.id AND n1.id = ci.person_id AND ci.movie_id = t.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.role_id = rt.id AND a1.person_id = ci.person_id AND ci.movie_id = mc.movie_id
AND cn.md5sum > 'b0c148389bce3ce05c56a9ae52629560' AND t.production_year IN (1906, 1952, 1957, 1958) AND ci.nr_order IN (1, 1032, 11001, 1306, 1701, 4004, 481, 527, 76) AND n1.imdb_index > 'LXXX';