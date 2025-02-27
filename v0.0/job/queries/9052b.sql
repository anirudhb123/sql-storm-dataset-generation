SELECT min(chn.name) AS character, min(t.title) AS russian_mov_with_actor_producer
FROM char_name AS chn, cast_info AS ci, company_name AS cn, company_type AS ct, movie_companies AS mc, role_type AS rt, title AS t
WHERE t.id = mc.movie_id AND t.id = ci.movie_id AND ci.movie_id = mc.movie_id AND chn.id = ci.person_role_id AND rt.id = ci.role_id AND cn.id = mc.company_id AND ct.id = mc.company_type_id
AND ci.note IS NOT NULL AND chn.surname_pcode IN ('C6232', 'I1253', 'M65', 'R1432', 'R2314', 'S5342', 'V4316', 'Z64') AND t.md5sum > '4a4ea4bbac095fb07945bd6225716a4c';