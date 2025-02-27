SELECT min(mc.note) AS production_note, min(t.title) AS movie_title, min(t.production_year) AS movie_year
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info_idx AS mi_idx, title AS t
WHERE ct.id = mc.company_type_id AND t.id = mc.movie_id AND t.id = mi_idx.movie_id AND mc.movie_id = mi_idx.movie_id AND it.id = mi_idx.info_type_id
AND ct.kind < 'production companies' AND t.season_nr < 34 AND mi_idx.movie_id IN (1204014, 142309, 1487131, 1634235, 1717490, 1925927, 2116795, 2366167, 426008) AND ct.id IN (1);