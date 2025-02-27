SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND mc.id < 582662 AND mi.movie_id < 1697557 AND t.phonetic_code < 'V3134' AND t.id IN (2258103, 23769, 2390544, 587833, 714638) AND mc.company_id < 156658;