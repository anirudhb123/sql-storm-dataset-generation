SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND it.id > 12 AND ct.id < 3 AND mi.info < 'Show received critical acclaim and congratulatory certificate from LA Mayor, Antonio Villaraigosa.' AND mc.company_id > 233849 AND t.phonetic_code IS NOT NULL;