SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND mc.movie_id > 803946 AND it.info IN ('LD disc size', 'LD group genre', 'LD video artifacts', 'goofs', 'interviews', 'mini biography', 'release dates', 'salary history');