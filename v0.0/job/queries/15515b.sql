SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND t.series_years IN ('1950-1958', '1968-1982', '2009-????') AND mc.id > 276079 AND mc.company_type_id = 1 AND mi.id > 6317329;