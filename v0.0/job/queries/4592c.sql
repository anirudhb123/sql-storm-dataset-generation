SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND t.md5sum > '73712e224eb0efd4936241a8c3ec2c73' AND mc.note < '(as Rasputin Prods.)' AND mi.id < 12506216 AND t.series_years > '1988-2007';