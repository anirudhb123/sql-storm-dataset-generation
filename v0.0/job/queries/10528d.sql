SELECT min(mc.note) AS production_note, min(t.title) AS movie_title, min(t.production_year) AS movie_year
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info_idx AS mi_idx, title AS t
WHERE ct.id = mc.company_type_id AND t.id = mc.movie_id AND t.id = mi_idx.movie_id AND mc.movie_id = mi_idx.movie_id AND it.id = mi_idx.info_type_id
AND t.series_years > '1972-1981' AND mi_idx.movie_id < 2076360 AND mi_idx.id IN (180954, 181158, 311248, 453632, 634488, 765156, 816162, 908222) AND ct.id IN (2) AND it.info > 'plot';