SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND t.kind_id < 3 AND mc.note < '(as Bord Scannán na hÉireann / The Irish Film Board) (with the participation of)' AND t.id > 480543 AND mi.info_type_id < 103;