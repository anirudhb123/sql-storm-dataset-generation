SELECT min(mc.note) AS production_note, min(t.title) AS movie_title, min(t.production_year) AS movie_year
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info_idx AS mi_idx, title AS t
WHERE ct.id = mc.company_type_id AND t.id = mc.movie_id AND t.id = mi_idx.movie_id AND mc.movie_id = mi_idx.movie_id AND it.id = mi_idx.info_type_id
AND mc.company_id < 44581 AND ct.kind = 'distributors' AND mc.note LIKE '%(worldwide)%' AND t.production_year IN (1889, 1890, 1911, 1927, 1940, 1954, 1965, 1980, 2012, 2016);