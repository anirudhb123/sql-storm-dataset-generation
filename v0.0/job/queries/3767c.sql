SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND mc.company_id > 58906 AND mi.note > '(1912)' AND t.title IN ('Bilocativ', 'La llum del silenci', 'Pozdrowienia z Lodzi', 'Shunkinshô', 'Tesão, Ninfetas Deliciosas', 'Zwei Girls vom roten Stern');