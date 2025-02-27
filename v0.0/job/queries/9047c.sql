SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND t.production_year > 1936 AND mi.note IN ('(Berlin station)', '(Hull International Film Festival)', '(New York Asian Film Festival) (premiere)', '(segment "Muffy and the Big Bad Blog")', '(video and still reference photography)', 'Scott Hillhouse');