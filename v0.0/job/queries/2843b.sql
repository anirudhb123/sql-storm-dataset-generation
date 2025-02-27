SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND mi.note IN ('(2048x1080)', '(6 reels) (5,084-5,400 ft.) (USA)', '(6 reels) (5095-5695 ft.)', '(Czech Republic)', '(Festival Ciné Poème)', '(Genève)', 'Eric Chisholm', 'diablo');