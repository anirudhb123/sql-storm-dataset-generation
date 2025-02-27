SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND it.info < 'LD review' AND mc.id < 602169 AND t.phonetic_code < 'R2536' AND t.md5sum > 'dae7e7333f15cc770c65aff6c53401dc';