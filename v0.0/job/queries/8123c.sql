SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND t.id IN (112004, 1130959, 2439712, 855201) AND t.md5sum > 'ca24136930c51889c41773343e51d3ca' AND t.kind_id IN (1, 7);