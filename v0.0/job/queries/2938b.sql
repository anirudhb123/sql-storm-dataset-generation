SELECT min(mc.note) AS production_note, min(t.title) AS movie_title, min(t.production_year) AS movie_year
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info_idx AS mi_idx, title AS t
WHERE ct.id = mc.company_type_id AND t.id = mc.movie_id AND t.id = mi_idx.movie_id AND mc.movie_id = mi_idx.movie_id AND it.id = mi_idx.info_type_id
AND t.md5sum IN ('0fe22e8c2cd9b9311fcf4703434b00ec', '18c179d0bace289fcc6edc075e6e801b', '3d87174e9de9e1987d364977fdec30c8', '670a9c904d0e9e74abc32f82e4b080e1', 'f0cf5508351dd12eec9c7ccf35b2375f', 'f391bb87adf5c1c50a7973a15c795b4b');