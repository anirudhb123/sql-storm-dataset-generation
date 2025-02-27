SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.imdb_index < 'XIX' AND k.keyword < 'two-man-shelter' AND t.md5sum < 'e53d743b13236c1643bdeb0f79c8f6e7' AND mi.info_type_id < 50 AND mi.id < 11186974;