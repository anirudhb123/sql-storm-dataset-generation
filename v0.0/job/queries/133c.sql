SELECT min(mc.note) AS production_note, min(t.title) AS movie_title, min(t.production_year) AS movie_year
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info_idx AS mi_idx, title AS t
WHERE ct.id = mc.company_type_id AND t.id = mc.movie_id AND t.id = mi_idx.movie_id AND mc.movie_id = mi_idx.movie_id AND it.id = mi_idx.info_type_id
AND t.md5sum > '6ca91fe20d6a949dd48b31a5dd3a0fa2' AND mc.note IS NOT NULL AND t.series_years IN ('1200-1350', '1956-1992', '1959-1990', '1963-1999', '1969-1987', '1989-2000', '1989-2005', '1993-2000');