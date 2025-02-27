SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND mc.note IN ('(1936) (Netherlands) (theatrical) (as Columbia Films of Netherlands Indies Ltd.)', '(1998) (New Zealand) (TV)', '(2010) (Romania) (DVD)', '(presents) (as Apollo Media Filmproduktion)');