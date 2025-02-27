SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND t.md5sum IN ('5d83053a2dc95856543699d2191010d8', '8a4f9f86726795024435e6d5edf6efac') AND t.kind_id = 7 AND mc.note IS NOT NULL AND ct.kind < 'miscellaneous companies' AND t.title > 'Neighborhood Gems';