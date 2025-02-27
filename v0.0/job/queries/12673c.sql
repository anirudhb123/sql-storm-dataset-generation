SELECT min(mc.note) AS production_note, min(t.title) AS movie_title, min(t.production_year) AS movie_year
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info_idx AS mi_idx, title AS t
WHERE ct.id = mc.company_type_id AND t.id = mc.movie_id AND t.id = mi_idx.movie_id AND mc.movie_id = mi_idx.movie_id AND it.id = mi_idx.info_type_id
AND mi_idx.info_type_id < 100 AND t.series_years IN ('1789-1812', '1961-1963', '1968-2001', '1981-1981', '1982-2001', '1992-2005', '1993-2007', '2010-????');