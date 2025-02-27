SELECT min(mc.note) AS production_note, min(t.title) AS movie_title, min(t.production_year) AS movie_year
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info_idx AS mi_idx, title AS t
WHERE ct.id = mc.company_type_id AND t.id = mc.movie_id AND t.id = mi_idx.movie_id AND mc.movie_id = mi_idx.movie_id AND it.id = mi_idx.info_type_id
AND mi_idx.info IN ('..111.00.2', '.0.12310.0', '.1..21111.', '0....00402', '0....14..3', '012113...1', '1..1010.03', '1111.11..3', '4..11.1..3', '9...0....0') AND mi_idx.movie_id > 453878;