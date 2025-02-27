SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND mc.note IN ('(1998) (Bulgaria) (theatrical)', '(2010) (USA) (video) (webcaster)', '(2011) (USA) (DVD) (25th Anniversary Edition)', '(2011) (USA) (digital)', '(as Vivid Man Video)', '(co-production) (as BBC)', '(producer) (as Big Stack)');