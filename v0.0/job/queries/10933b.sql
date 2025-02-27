SELECT min(chn.name) AS character, min(t.title) AS russian_mov_with_actor_producer
FROM char_name AS chn, cast_info AS ci, company_name AS cn, company_type AS ct, movie_companies AS mc, role_type AS rt, title AS t
WHERE t.id = mc.movie_id AND t.id = ci.movie_id AND ci.movie_id = mc.movie_id AND chn.id = ci.person_role_id AND rt.id = ci.role_id AND cn.id = mc.company_id AND ct.id = mc.company_type_id
AND chn.md5sum IN ('0a9a431638dfbd0755feecc6b4f77254', '63039a0029bb2c8a6d6701d4b02381aa', 'a82864c1ef6c848f6eae7e573bbda193');