SELECT min(mc.note) AS production_note, min(t.title) AS movie_title, min(t.production_year) AS movie_year
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info_idx AS mi_idx, title AS t
WHERE ct.id = mc.company_type_id AND t.id = mc.movie_id AND t.id = mi_idx.movie_id AND mc.movie_id = mi_idx.movie_id AND it.id = mi_idx.info_type_id
AND t.production_year IN (1913, 1915, 1927, 1937, 1946, 1956, 1962, 1992, 2015) AND t.kind_id > 0 AND mi_idx.id < 1157365 AND mc.note IS NOT NULL AND it.info > 'certificates';