SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND t.series_years IN ('1918-1923', '1958-1965', '1969-1997', '1976-1981', '1985-1999', '1992-????', '1993-1998', '1998-2012') AND mc.note > '(2010) (USA) (DVD) (Celebrated Women of Color Film Collection Vol. 1)';