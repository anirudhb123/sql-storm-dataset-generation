SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND t.episode_nr IS NOT NULL AND t.episode_of_id IN (823930) AND t.md5sum > '7a50b1d0d35c239fb47444b8dd8b53f8' AND ct.kind > 'distributors' AND t.season_nr < 67;