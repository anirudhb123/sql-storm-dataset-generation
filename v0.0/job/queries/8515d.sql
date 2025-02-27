SELECT min(mc.note) AS production_note, min(t.title) AS movie_title, min(t.production_year) AS movie_year
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info_idx AS mi_idx, title AS t
WHERE ct.id = mc.company_type_id AND t.id = mc.movie_id AND t.id = mi_idx.movie_id AND mc.movie_id = mi_idx.movie_id AND it.id = mi_idx.info_type_id
AND t.phonetic_code IS NOT NULL AND t.production_year < 1954 AND mi_idx.info_type_id > 99 AND mi_idx.info < '40.0001.02' AND mi_idx.movie_id > 2141413 AND mc.note IS NOT NULL;