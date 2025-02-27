SELECT min(mc.note) AS production_note, min(t.title) AS movie_title, min(t.production_year) AS movie_year
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info_idx AS mi_idx, title AS t
WHERE ct.id = mc.company_type_id AND t.id = mc.movie_id AND t.id = mi_idx.movie_id AND mc.movie_id = mi_idx.movie_id AND it.id = mi_idx.info_type_id
AND mc.company_type_id IN (1) AND mi_idx.info IN ('..10022011', '..101111.3', '.0.1.01311', '0...0.4001', '0010001003', '0011121000', '10....0014', '2500.00001', '3.11001001') AND mi_idx.movie_id > 1196924;