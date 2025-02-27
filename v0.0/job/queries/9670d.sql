SELECT min(mc.note) AS production_note, min(t.title) AS movie_title, min(t.production_year) AS movie_year
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info_idx AS mi_idx, title AS t
WHERE ct.id = mc.company_type_id AND t.id = mc.movie_id AND t.id = mi_idx.movie_id AND mc.movie_id = mi_idx.movie_id AND it.id = mi_idx.info_type_id
AND mc.movie_id IN (1484042, 183568, 1875308, 2166640, 2231357, 2317690, 2421813, 2491617, 822103) AND t.production_year IN (1894, 1896, 1911, 1942, 1956, 1976, 1997, 2017);