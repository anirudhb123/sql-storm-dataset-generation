SELECT min(mc.note) AS production_note, min(t.title) AS movie_title, min(t.production_year) AS movie_year
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info_idx AS mi_idx, title AS t
WHERE ct.id = mc.company_type_id AND t.id = mc.movie_id AND t.id = mi_idx.movie_id AND mc.movie_id = mi_idx.movie_id AND it.id = mi_idx.info_type_id
AND t.production_year < 1996 AND mi_idx.info IN ('....022.20', '...0.24000', '.21.10.0.4', '0.000.0007', '00..102122', '1.0....015', '10032000.0', '11.21.2.12', '28997');