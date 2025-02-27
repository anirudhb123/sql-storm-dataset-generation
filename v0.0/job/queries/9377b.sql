SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND t.md5sum IN ('071901959fc49505c723d3a73736a3a1', '22383d4d21407a3499824b6ed8b09db7', '85ddf133c3aa2211c55536ff1eada642', 'f65b3f1d11c014057c8c20605017c86d');