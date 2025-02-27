SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND t.production_year IS NOT NULL AND mi.note IN ('(Omaha, Nebraska) (premiere)', '(PCA #13393)', '(film laboratory) (as Soho Images)', 'Clinton Lim', 'Concord') AND mc.company_type_id IN (1, 2) AND mc.note < '(as Cinematográfica Grovas, S.A.)' AND mi.info_type_id < 85;