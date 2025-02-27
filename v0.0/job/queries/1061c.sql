SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND ct.kind < 'production companies' AND mi.info_type_id > 6 AND mc.movie_id > 1685145 AND t.phonetic_code < 'T6214' AND it.info = 'LD subtitles' AND t.md5sum IS NOT NULL AND mc.note IS NOT NULL;