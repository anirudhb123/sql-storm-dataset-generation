SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND t.series_years IN ('1939-????', '1948-1966', '1950-1953', '1951-1999', '1959-1999', '1961-1988', '1964-2012', '1969-1976', '1970-1993', '1988-2002') AND mi.note > '<raq@netcom.com>';