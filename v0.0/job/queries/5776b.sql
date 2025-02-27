SELECT min(mc.note) AS production_note, min(t.title) AS movie_title, min(t.production_year) AS movie_year
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info_idx AS mi_idx, title AS t
WHERE ct.id = mc.company_type_id AND t.id = mc.movie_id AND t.id = mi_idx.movie_id AND mc.movie_id = mi_idx.movie_id AND it.id = mi_idx.info_type_id
AND t.production_year > 1920 AND mi_idx.info IN ('.....20014', '....3311.2', '..011130.0', '0....04300', '10.0..1113', '1010000101', '210....0.5', '2102.0.1.1') AND t.series_years IS NOT NULL;