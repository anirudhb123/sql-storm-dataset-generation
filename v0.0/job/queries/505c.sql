SELECT min(chn.name) AS character, min(t.title) AS russian_mov_with_actor_producer
FROM char_name AS chn, cast_info AS ci, company_name AS cn, company_type AS ct, movie_companies AS mc, role_type AS rt, title AS t
WHERE t.id = mc.movie_id AND t.id = ci.movie_id AND ci.movie_id = mc.movie_id AND chn.id = ci.person_role_id AND rt.id = ci.role_id AND cn.id = mc.company_id AND ct.id = mc.company_type_id
AND cn.id < 62699 AND chn.imdb_index LIKE '%I%' AND cn.name_pcode_sf LIKE '%1%' AND ct.kind IN ('miscellaneous companies', 'production companies') AND t.md5sum < 'a8b6ab54ae3a13274461e321b405b57c';