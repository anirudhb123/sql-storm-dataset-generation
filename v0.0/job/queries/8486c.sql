SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND mi.note IN ('(Experimental Media and Performing Arts Center)', '(Kodak Vision2 50D 7201, Vision2 250D 7205, Vision2 100T 7212, Vision2 200T 7217, Vision2 500T 7218)', '(Rakkautta and Anarkiaa Festival)', '(color) (as Guffanti)', 'DFI - Danish Film Institute', 'Paul Festa') AND mi.info_type_id < 16;