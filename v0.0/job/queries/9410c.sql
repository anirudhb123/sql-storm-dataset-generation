SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND t.phonetic_code > 'S1513' AND mc.company_id < 152618 AND it.info IN ('budget', 'goofs') AND mc.note > '(as Lamond Motion Picture Enterprises)';