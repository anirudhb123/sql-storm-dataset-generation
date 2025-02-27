SELECT min(mc.note) AS production_note, min(t.title) AS movie_title, min(t.production_year) AS movie_year
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info_idx AS mi_idx, title AS t
WHERE ct.id = mc.company_type_id AND t.id = mc.movie_id AND t.id = mi_idx.movie_id AND mc.movie_id = mi_idx.movie_id AND it.id = mi_idx.info_type_id
AND mi_idx.info IN ('.....00.16', '.0.0000411', '.1..31.11.', '0...102113', '0002221...', '1...211122', '1.0.041.0.', '11...1.0.4', '3..2.22..1', '6...22....') AND t.episode_of_id > 905463;