SELECT min(mc.note) AS production_note, min(t.title) AS movie_title, min(t.production_year) AS movie_year
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info_idx AS mi_idx, title AS t
WHERE ct.id = mc.company_type_id AND t.id = mc.movie_id AND t.id = mi_idx.movie_id AND mc.movie_id = mi_idx.movie_id AND it.id = mi_idx.info_type_id
AND t.series_years IN ('1978-1987', '1989-1996', '1990-1995', '2006-????') AND mi_idx.id < 489942 AND t.md5sum > 'bc2b086db66baa0aa0a13e9860f4bfeb';