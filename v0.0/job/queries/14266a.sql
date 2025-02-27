SELECT min(chn.name) AS character, min(t.title) AS russian_mov_with_actor_producer
FROM char_name AS chn, cast_info AS ci, company_name AS cn, company_type AS ct, movie_companies AS mc, role_type AS rt, title AS t
WHERE t.id = mc.movie_id AND t.id = ci.movie_id AND ci.movie_id = mc.movie_id AND chn.id = ci.person_role_id AND rt.id = ci.role_id AND cn.id = mc.company_id AND ct.id = mc.company_type_id
AND chn.md5sum > 'd8361bdb84cb3163cdc960ea60abf5a9' AND t.kind_id IN (3, 7) AND t.phonetic_code IN ('B2353', 'D2641', 'D4525', 'H6163', 'K2345', 'V5643');