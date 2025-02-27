SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND k.phonetic_code IS NOT NULL AND mi.info_type_id IN (1, 105, 42, 43, 46, 48, 73, 9, 92);