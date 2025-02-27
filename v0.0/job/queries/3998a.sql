SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND t.episode_of_id IS NOT NULL AND mi.info = 'FACT: During the shoot out in the hotel room, Ryker is using a revolver with a sound suppressor. A sound suppressor is absolutely useless on a revolver, since the muzzle gases leave already at the gap between the drum and the barrel, hence a bang is already audible.';