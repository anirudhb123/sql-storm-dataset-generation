SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND t.kind_id > 3 AND t.md5sum > '32de39b98996200a17df80bfbef4c1bc' AND t.production_year IS NOT NULL AND mi.info_type_id IN (15);