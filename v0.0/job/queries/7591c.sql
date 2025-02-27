SELECT min(mc.note) AS production_note, min(t.title) AS movie_title, min(t.production_year) AS movie_year
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info_idx AS mi_idx, title AS t
WHERE ct.id = mc.company_type_id AND t.id = mc.movie_id AND t.id = mi_idx.movie_id AND mc.movie_id = mi_idx.movie_id AND it.id = mi_idx.info_type_id
AND t.title > 'O rany, nic sie nie stalo' AND ct.kind IN ('production companies') AND t.production_year IN (1892, 1922, 1929, 1938, 1943, 1952, 1956, 1977, 1991, 2007);