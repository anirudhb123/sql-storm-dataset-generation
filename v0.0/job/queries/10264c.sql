SELECT min(mc.note) AS production_note, min(t.title) AS movie_title, min(t.production_year) AS movie_year
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info_idx AS mi_idx, title AS t
WHERE ct.id = mc.company_type_id AND t.id = mc.movie_id AND t.id = mi_idx.movie_id AND mc.movie_id = mi_idx.movie_id AND it.id = mi_idx.info_type_id
AND t.production_year IN (1892, 1902, 1906, 1908, 1942, 1951, 1969, 2011) AND t.phonetic_code IN ('C5154', 'D6362', 'H1514', 'H6363', 'N1256', 'O5262', 'W2562', 'Y5631') AND mi_idx.movie_id < 1988946;