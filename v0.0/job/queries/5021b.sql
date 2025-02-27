SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND t.phonetic_code IN ('C1314', 'C5465', 'D2612', 'F1342', 'J525', 'M6562', 'S6134', 'V1351', 'W5251', 'X1643');