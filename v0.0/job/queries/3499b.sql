SELECT min(mc.note) AS production_note, min(t.title) AS movie_title, min(t.production_year) AS movie_year
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info_idx AS mi_idx, title AS t
WHERE ct.id = mc.company_type_id AND t.id = mc.movie_id AND t.id = mi_idx.movie_id AND mc.movie_id = mi_idx.movie_id AND it.id = mi_idx.info_type_id
AND mi_idx.movie_id IN (1197291, 1647746, 1672912, 1754704, 1812687, 1825517, 1856550, 2423944, 2451949, 635671) AND mi_idx.info < '0.12012..0' AND t.production_year > 1950;