SELECT min(a1.name) AS writer_pseudo_name, min(t.title) AS movie_title
FROM aka_name AS a1, cast_info AS ci, company_name AS cn, movie_companies AS mc, name AS n1, role_type AS rt, title AS t
WHERE a1.person_id = n1.id AND n1.id = ci.person_id AND ci.movie_id = t.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.role_id = rt.id AND a1.person_id = ci.person_id AND ci.movie_id = mc.movie_id
AND t.id > 543591 AND t.season_nr > 4 AND t.episode_nr IN (113, 12565, 1296, 1479, 3351, 4851, 5711, 7968, 8463, 8992) AND rt.id IN (11, 12, 2, 4, 5, 6, 8, 9);