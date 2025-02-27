SELECT min(mc.note) AS production_note, min(t.title) AS movie_title, min(t.production_year) AS movie_year
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info_idx AS mi_idx, title AS t
WHERE ct.id = mc.company_type_id AND t.id = mc.movie_id AND t.id = mi_idx.movie_id AND mc.movie_id = mi_idx.movie_id AND it.id = mi_idx.info_type_id
AND mc.company_type_id IN (1) AND t.kind_id IN (0, 1, 2, 3, 4, 6, 7) AND t.season_nr = 31 AND mi_idx.info_type_id = 99 AND mc.company_id < 147116;