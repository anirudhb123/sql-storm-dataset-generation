SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND mi.info > '3,386,523 (Italy) (6 June 2004)' AND t.md5sum IS NOT NULL AND t.phonetic_code IS NOT NULL AND k.id < 112294 AND t.id > 209499;