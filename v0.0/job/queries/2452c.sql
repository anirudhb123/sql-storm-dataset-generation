SELECT min(chn.name) AS character, min(t.title) AS russian_mov_with_actor_producer
FROM char_name AS chn, cast_info AS ci, company_name AS cn, company_type AS ct, movie_companies AS mc, role_type AS rt, title AS t
WHERE t.id = mc.movie_id AND t.id = ci.movie_id AND ci.movie_id = mc.movie_id AND chn.id = ci.person_role_id AND rt.id = ci.role_id AND cn.id = mc.company_id AND ct.id = mc.company_type_id
AND chn.id > 3011890 AND ci.id > 10294694 AND t.production_year IN (1900, 1945, 1949, 1959, 1981);