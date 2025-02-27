SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND k.keyword < 'reference-to-james-woods' AND mi.movie_id > 1047789 AND t.phonetic_code > 'A2145' AND mi.note = '(Finland) (70 mm version)';