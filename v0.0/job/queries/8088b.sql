SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.production_year IN (1903, 1909, 1910, 1921, 1941, 1942, 1950, 1992, 1998, 2006) AND mi.note > '(Freak Out Halloween Film Festival, Wilmington NC)' AND t.md5sum IS NOT NULL;