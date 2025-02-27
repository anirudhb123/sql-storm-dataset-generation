SELECT min(mc.note) AS production_note, min(t.title) AS movie_title, min(t.production_year) AS movie_year
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info_idx AS mi_idx, title AS t
WHERE ct.id = mc.company_type_id AND t.id = mc.movie_id AND t.id = mi_idx.movie_id AND mc.movie_id = mi_idx.movie_id AND it.id = mi_idx.info_type_id
AND t.md5sum > 'c35502185947a9491c6755dc261f48ed' AND mc.id < 1459014 AND t.episode_of_id IN (1189650, 1315872, 1420995, 248104, 299431, 375574, 485181, 738193, 837677, 8635);