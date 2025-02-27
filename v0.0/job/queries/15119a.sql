SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND it.info IN ('LD disc format', 'LD disc size', 'LD number of chapter stops', 'LD original title', 'color info', 'mpaa', 'production process protocol', 'quotes', 'taglines') AND t.production_year < 1993 AND mc.company_type_id IN (1, 2);