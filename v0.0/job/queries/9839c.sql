SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND mi.info < 'Baron Von Klutz: [thick German accent] So Crumpetts, I see you are having some trouble with your car.::T.N. Crumpetts: I see you are having some trouble with your accent.' AND t.phonetic_code = 'H4514' AND mc.id < 648798;