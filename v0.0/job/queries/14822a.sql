SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND t.production_year < 1976 AND t.episode_of_id IS NOT NULL AND t.phonetic_code IN ('I2563', 'M6153', 'N1635', 'V3653', 'V5463', 'Z4532');