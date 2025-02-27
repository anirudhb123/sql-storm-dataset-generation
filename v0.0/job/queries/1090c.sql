SELECT min(mc.note) AS production_note, min(t.title) AS movie_title, min(t.production_year) AS movie_year
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info_idx AS mi_idx, title AS t
WHERE ct.id = mc.company_type_id AND t.id = mc.movie_id AND t.id = mi_idx.movie_id AND mc.movie_id = mi_idx.movie_id AND it.id = mi_idx.info_type_id
AND mi_idx.id IN (1102106, 114014, 1245294, 292821, 292849, 469858, 688965) AND t.md5sum < '5fc64a2fb9ada3262df26c7b53ac6277' AND mi_idx.movie_id < 2286834;