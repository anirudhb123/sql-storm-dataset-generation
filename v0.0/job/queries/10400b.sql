SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND t.title > 'Mama na brzakakao' AND it.info IN ('LD aspect ratio', 'LD quality program', 'LD video artifacts', 'color info', 'production process protocol') AND ct.id > 1 AND mc.company_id > 42264;