SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND t.md5sum IS NOT NULL AND mc.note IN ('(1949) (USA) (theatrical) (R K O Radio Pictures, Inc.)', '(1959) (Poland) (TV)', '(1982) (UK) (TV)', '(1992-1994) (Australia) (TV)', '(1998) (non-USA) (all media)', '(2011) (USA) (DVD) (included in "Poldark: The Complete collection")');