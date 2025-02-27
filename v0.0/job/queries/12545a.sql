SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND t.md5sum > '9b4256bd3b56385d68cc4271e7fd8137' AND mi.movie_id < 2316638 AND t.season_nr IN (102, 1992, 1999, 2, 2011, 50, 55, 58) AND mc.note > '(2006) (Germany) (DVD) (special edition)';