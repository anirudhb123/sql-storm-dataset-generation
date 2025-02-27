SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND t.series_years IN ('1961-1978', '1971-1985', '1980-1990', '1981-1991', '1984-1996', '1986-1995', '1989-2004', '1996-2006', '1998-2012');