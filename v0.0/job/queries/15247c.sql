SELECT min(mc.note) AS production_note, min(t.title) AS movie_title, min(t.production_year) AS movie_year
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info_idx AS mi_idx, title AS t
WHERE ct.id = mc.company_type_id AND t.id = mc.movie_id AND t.id = mi_idx.movie_id AND mc.movie_id = mi_idx.movie_id AND it.id = mi_idx.info_type_id
AND it.info IN ('LD audio noise', 'LD original title', 'LD quality program', 'countries', 'interviews', 'novel', 'production dates', 'rating', 'taglines') AND t.episode_of_id < 902315 AND mc.id > 408805;