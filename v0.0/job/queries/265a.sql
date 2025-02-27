SELECT min(mc.note) AS production_note, min(t.title) AS movie_title, min(t.production_year) AS movie_year
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info_idx AS mi_idx, title AS t
WHERE ct.id = mc.company_type_id AND t.id = mc.movie_id AND t.id = mi_idx.movie_id AND mc.movie_id = mi_idx.movie_id AND it.id = mi_idx.info_type_id
AND t.kind_id IN (0, 2, 3, 4, 6, 7) AND mi_idx.info IN ('.....16..3', '....1430..', '...1.6..1.', '..0.110121', '1..12131..', '11..1...04') AND t.phonetic_code > 'S6323';