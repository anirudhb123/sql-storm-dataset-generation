SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND it.info IN ('LD catalog number', 'LD pressing plant', 'LD quality program', 'countries', 'crazy credits', 'interviews', 'locations', 'quotes', 'release dates', 'sound mix') AND t.series_years IS NOT NULL AND t.production_year IN (1911, 1922, 1928, 1951, 1976, 1986, 2015, 2017) AND t.id > 461175;