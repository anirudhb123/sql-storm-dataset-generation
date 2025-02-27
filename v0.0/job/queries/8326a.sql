SELECT min(chn.name) AS character, min(t.title) AS russian_mov_with_actor_producer
FROM char_name AS chn, cast_info AS ci, company_name AS cn, company_type AS ct, movie_companies AS mc, role_type AS rt, title AS t
WHERE t.id = mc.movie_id AND t.id = ci.movie_id AND ci.movie_id = mc.movie_id AND chn.id = ci.person_role_id AND rt.id = ci.role_id AND cn.id = mc.company_id AND ct.id = mc.company_type_id
AND mc.id > 1093537 AND t.md5sum > 'd9d82bc35fe40001daf97b12de68a1f0' AND chn.surname_pcode LIKE '%41%' AND cn.md5sum IS NOT NULL AND t.episode_nr < 474;