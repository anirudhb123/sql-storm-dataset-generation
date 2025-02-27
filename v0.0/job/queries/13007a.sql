SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND mi.note IN ('(Jimmy highland retreat)', '(Virginia is seen entering this building for her sex therapy)', '(house in Long Island)', '(opening scenes and elevator)', '(photo laboratory)', 'Bradley H. Luft', 'LOGOonline', 'Martin Leclerc', 'Michael Wright', 'Paige Griffin');