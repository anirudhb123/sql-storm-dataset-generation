SELECT min(mc.note) AS production_note, min(t.title) AS movie_title, min(t.production_year) AS movie_year
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info_idx AS mi_idx, title AS t
WHERE ct.id = mc.company_type_id AND t.id = mc.movie_id AND t.id = mi_idx.movie_id AND mc.movie_id = mi_idx.movie_id AND it.id = mi_idx.info_type_id
AND mc.note > '(as An Osmond Entertainment Production)' AND t.title > '30 min. med Susanne Ravn' AND t.md5sum < '3bc6dc880e8c32af11f3e16cd45f1460' AND ct.id > 1;