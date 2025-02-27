SELECT min(mc.note) AS production_note, min(t.title) AS movie_title, min(t.production_year) AS movie_year
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info_idx AS mi_idx, title AS t
WHERE ct.id = mc.company_type_id AND t.id = mc.movie_id AND t.id = mi_idx.movie_id AND mc.movie_id = mi_idx.movie_id AND it.id = mi_idx.info_type_id
AND t.title > 'Arròs congelat' AND mi_idx.info LIKE '%1%' AND t.md5sum < 'd1f9dfc539da819567b3ce95af600f94' AND mi_idx.id IN (1159938, 1169144, 1266022, 648852, 704362, 731090, 745983, 777656, 959327);