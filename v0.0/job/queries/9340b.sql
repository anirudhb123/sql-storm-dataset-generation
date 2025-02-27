SELECT min(mc.note) AS production_note, min(t.title) AS movie_title, min(t.production_year) AS movie_year
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info_idx AS mi_idx, title AS t
WHERE ct.id = mc.company_type_id AND t.id = mc.movie_id AND t.id = mi_idx.movie_id AND mc.movie_id = mi_idx.movie_id AND it.id = mi_idx.info_type_id
AND t.production_year IS NOT NULL AND t.episode_nr < 15404 AND t.md5sum > 'f71413e35a6d647e1d598436d7cd912f' AND ct.kind < 'miscellaneous companies' AND t.season_nr < 7 AND mc.company_type_id IN (1, 2);