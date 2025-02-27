SELECT min(mc.note) AS production_note, min(t.title) AS movie_title, min(t.production_year) AS movie_year
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info_idx AS mi_idx, title AS t
WHERE ct.id = mc.company_type_id AND t.id = mc.movie_id AND t.id = mi_idx.movie_id AND mc.movie_id = mi_idx.movie_id AND it.id = mi_idx.info_type_id
AND t.title IN ('(1999-01-09)', 'Change of Heart, Change of Hands', 'Office Rumours', 'Santiago vs. Wigface', 'The Bronson Pinchot Project', 'The Hollywood Starlet Search', 'Thought of You', 'Óstán Na Gcroíthe Briste');