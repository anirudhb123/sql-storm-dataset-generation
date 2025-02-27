SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND mi.info_type_id IN (18, 6, 80, 93) AND t.md5sum > '780370b19f36984005dcabbc4294b611' AND t.phonetic_code IN ('F3451', 'L5315', 'N1625', 'Q1315');