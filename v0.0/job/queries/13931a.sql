SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND ct.kind < 'special effects companies' AND mc.movie_id IN (1314584, 1418845, 1709371, 1735325, 2130552, 2189689, 2255358) AND t.title > 'Koboreru tsuki' AND t.md5sum < '831c73a6f4aa43fbf6dec8158df49f91' AND mc.company_type_id IN (2);