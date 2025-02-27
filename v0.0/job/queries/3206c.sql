SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND mi.note IS NOT NULL AND t.phonetic_code > 'C3435' AND t.kind_id > 4 AND mc.note > '(1937) (USA) (theatrical) (released through) (as Twentieth Century-Fox Film Corporation)' AND mc.company_type_id > 1;