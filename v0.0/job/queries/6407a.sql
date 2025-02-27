SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND t.md5sum IN ('5670d8a46cc999aa4cc6350ce54538d3', '75ef9d4d3df5eb22a632d2dd05bd8aec', '7a4a4d24dda9e9aaa97ccddef2177541', '87ddba328b2a683d9a804bb9245e0004', 'ae76ce5746f33aa4a232534a63e4c1e2', 'b7e6a8c30e13d6679b23069f552f0772') AND mc.id > 439521;