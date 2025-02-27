SELECT min(mc.note) AS production_note, min(t.title) AS movie_title, min(t.production_year) AS movie_year
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info_idx AS mi_idx, title AS t
WHERE ct.id = mc.company_type_id AND t.id = mc.movie_id AND t.id = mi_idx.movie_id AND mc.movie_id = mi_idx.movie_id AND it.id = mi_idx.info_type_id
AND t.md5sum > '43fee934690c3c6b558e74d3abe47f82' AND t.production_year IN (1880, 1905, 1917, 1957, 1992, 2005, 2007) AND t.kind_id > 0 AND mi_idx.info_type_id = 112;