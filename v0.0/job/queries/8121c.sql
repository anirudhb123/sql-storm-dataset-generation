SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND mi.info_type_id > 5 AND t.production_year IS NOT NULL AND t.md5sum < '21ef47b9c4e1e2cf498780dafb9efb4c';