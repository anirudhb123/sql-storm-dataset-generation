SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND mi.info_type_id IN (17, 18, 42, 45, 66, 84, 9) AND t.md5sum > 'f68d07f4c2df2ab3078e55f9768d6fe3' AND mi.note < '(Certamen Latinoamericano de Cine y Video de Santa Fe [ar])';