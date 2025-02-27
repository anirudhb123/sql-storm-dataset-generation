SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND t.production_year IN (1908, 1978, 2007) AND it.info IN ('LD certification', 'LD year', 'copyright holder', 'release dates', 'rentals') AND mc.movie_id > 1887232 AND mi.info_type_id < 84;