SELECT min(chn.name) AS character, min(t.title) AS russian_mov_with_actor_producer
FROM char_name AS chn, cast_info AS ci, company_name AS cn, company_type AS ct, movie_companies AS mc, role_type AS rt, title AS t
WHERE t.id = mc.movie_id AND t.id = ci.movie_id AND ci.movie_id = mc.movie_id AND chn.id = ci.person_role_id AND rt.id = ci.role_id AND cn.id = mc.company_id AND ct.id = mc.company_type_id
AND chn.name > 'Anish Ranjan' AND t.production_year > 1938 AND ci.person_id IN (1456947, 1869720, 1991184, 2266044, 2550550, 3217928, 891503) AND ci.person_role_id > 609494;