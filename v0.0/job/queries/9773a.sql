SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND t.season_nr IN (1990, 2010, 30, 32, 52) AND mi.note > '(bank, as "Banque de Grenoble")' AND t.id < 343927 AND mc.movie_id < 2244344;