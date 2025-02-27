SELECT min(mc.note) AS production_note, min(t.title) AS movie_title, min(t.production_year) AS movie_year
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info_idx AS mi_idx, title AS t
WHERE ct.id = mc.company_type_id AND t.id = mc.movie_id AND t.id = mi_idx.movie_id AND mc.movie_id = mi_idx.movie_id AND it.id = mi_idx.info_type_id
AND t.production_year > 1975 AND t.id < 2167581 AND mi_idx.info < '1....23..2' AND mc.note < '(2012) (USA) (DVD) (Blu-ray) (triple feature with "Darkness" and "Venom")' AND t.phonetic_code IN ('K1514');