SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND t.md5sum IN ('137e2a42b47156193a9b3a9631c44ac3', '3b817b1665e7eec33198732b235ae90c', '4752482bf1d4db7bd5ad7fcc0d58c94d', '5ab61f8e06b5e95390ce74ce03e898e5', '73519002accb8a470b8a0433ff8d6658', 'b8ae483cdf7206ce0e5a902fbc300c37', 'c5c4ba664c5442ebf1bc903b91105604') AND t.episode_nr IS NOT NULL;