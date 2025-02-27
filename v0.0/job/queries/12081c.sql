SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.kind_id > 0 AND t.series_years > '1998-2001' AND t.md5sum > '253a0c18eeb86ef81ab883b3b9dc0219';