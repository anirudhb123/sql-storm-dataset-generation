SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND mc.note > '(1924) (USA) (theatrical) (states rights)' AND mi.id IN (10324187, 6808345, 7012131, 7958483, 9253310, 941931) AND it.info < 'rating' AND t.kind_id IN (1) AND ct.kind > 'distributors';