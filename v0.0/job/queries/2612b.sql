SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND mc.company_type_id IN (1, 2) AND mc.company_id IN (112913, 175971, 212218, 30514, 65645, 81651) AND t.md5sum < '9d666e12cc7ae49acd18aded4e7ddf69';