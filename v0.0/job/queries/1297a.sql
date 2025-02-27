SELECT min(chn.name) AS character, min(t.title) AS russian_mov_with_actor_producer
FROM char_name AS chn, cast_info AS ci, company_name AS cn, company_type AS ct, movie_companies AS mc, role_type AS rt, title AS t
WHERE t.id = mc.movie_id AND t.id = ci.movie_id AND ci.movie_id = mc.movie_id AND chn.id = ci.person_role_id AND rt.id = ci.role_id AND cn.id = mc.company_id AND ct.id = mc.company_type_id
AND ci.note > '(as Sidy Lamine Diara)' AND t.imdb_index < 'XIX' AND chn.md5sum < 'dc7e4b4ede58f062bf93228415ac003d' AND mc.note < '(as LIFT) (co-production)' AND ci.person_role_id < 1512478;