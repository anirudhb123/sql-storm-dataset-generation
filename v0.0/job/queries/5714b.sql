SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND t.production_year IS NOT NULL AND t.md5sum IN ('10db84e29fcee5673a3a35dbd4d32a6a', '1ca46aeabced0812f098c2393f485c2f', '3734eb74a19d0569c787030dcdad5dcf', '3e99e911b8d30bd16cc1ce3a27fa8b02', '6f5b8731597ccc2ff3d5a808eb37b1a5', '8a0f7f60b06c1393f9957f2cea8f9039', 'c70aaf3093701700b3d1b4e2822025e4');