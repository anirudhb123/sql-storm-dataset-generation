SELECT min(mc.note) AS production_note, min(t.title) AS movie_title, min(t.production_year) AS movie_year
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info_idx AS mi_idx, title AS t
WHERE ct.id = mc.company_type_id AND t.id = mc.movie_id AND t.id = mi_idx.movie_id AND mc.movie_id = mi_idx.movie_id AND it.id = mi_idx.info_type_id
AND mc.note < '(1974) (UK) (theatrical) (as EMI Film Distributors Ltd.)' AND mi_idx.movie_id IN (1753626, 1809145, 1824499, 386304, 54656) AND t.production_year < 2005;