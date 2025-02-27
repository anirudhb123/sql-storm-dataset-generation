SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND t.season_nr IS NOT NULL AND t.production_year < 1966 AND mi.info > 'CREW: Both times Alex is on the railing of the roof, the wire around her ankle is visible.' AND t.md5sum > '59a2f4487a5ecc9205018a9d544e17d0' AND t.episode_of_id < 806579 AND t.episode_nr IS NOT NULL;