SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND mc.note IN ('(1996) (Germany) (video)', '(2002) (Japan) (TV) (edited)', '(2003) (Denmark) (video)', '(2009) (Switzerland) (all media)', '(2010) (UK) (DVD) (PC version)', '(????) (Italy) (DVD) (soft core version)', '(producer) (as Le Studio Canal+)');