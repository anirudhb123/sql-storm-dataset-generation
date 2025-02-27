SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND k.phonetic_code IN ('A4262', 'B3213', 'C6326', 'G4512', 'H3425', 'T6426', 'V4346') AND mi.info LIKE '%this%';