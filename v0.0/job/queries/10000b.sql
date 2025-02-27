SELECT min(mc.note) AS production_note, min(t.title) AS movie_title, min(t.production_year) AS movie_year
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info_idx AS mi_idx, title AS t
WHERE ct.id = mc.company_type_id AND t.id = mc.movie_id AND t.id = mi_idx.movie_id AND mc.movie_id = mi_idx.movie_id AND it.id = mi_idx.info_type_id
AND mc.movie_id IN (1215379, 1994542, 2096281, 2113281, 2117079, 983131) AND mi_idx.movie_id < 2219510 AND t.kind_id IN (0, 1, 3, 4, 6, 7);