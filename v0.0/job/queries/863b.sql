SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND mc.note IS NOT NULL AND mc.movie_id IN (1728699, 1819292, 1931745, 2199759, 2216475, 456001, 757523) AND t.md5sum < 'b6056ac5beeda1ba2809d87309bb7072';