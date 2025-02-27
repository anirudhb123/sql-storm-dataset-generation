SELECT min(mc.note) AS production_note, min(t.title) AS movie_title, min(t.production_year) AS movie_year
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info_idx AS mi_idx, title AS t
WHERE ct.id = mc.company_type_id AND t.id = mc.movie_id AND t.id = mi_idx.movie_id AND mc.movie_id = mi_idx.movie_id AND it.id = mi_idx.info_type_id
AND t.series_years > '1992-2009' AND t.phonetic_code IN ('A5356', 'G1345', 'H3423', 'J5151', 'J6524', 'L3', 'R2164', 'R5254', 'T6316', 'U5216');