SELECT min(chn.name) AS character, min(t.title) AS russian_mov_with_actor_producer
FROM char_name AS chn, cast_info AS ci, company_name AS cn, company_type AS ct, movie_companies AS mc, role_type AS rt, title AS t
WHERE t.id = mc.movie_id AND t.id = ci.movie_id AND ci.movie_id = mc.movie_id AND chn.id = ci.person_role_id AND rt.id = ci.role_id AND cn.id = mc.company_id AND ct.id = mc.company_type_id
AND cn.country_code < '[so]' AND chn.id > 1093103 AND chn.name LIKE '%Sergeant%' AND t.episode_nr < 13625 AND t.season_nr IN (17, 28, 35, 48, 6, 66);