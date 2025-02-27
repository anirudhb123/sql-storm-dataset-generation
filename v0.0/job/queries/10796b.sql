SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND mi.note IN ('(Kodak Vision2 200T 7217, Vision3 500T 7219, Eastman EXR 50D 7245)', '(recording)', '(seasons 1-5)', 'Anisha J. King', 'Cal', 'Live Well Network', 'Nigel Christensen') AND mc.note > '(2009) (USA) (all media) (PlayStation 3 version) (download only) (as Numblast)';