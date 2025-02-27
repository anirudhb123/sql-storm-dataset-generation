SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.phonetic_code IN ('F1326', 'F1642', 'G1563', 'M5632', 'M6152', 'N4136', 'O3463', 'R1346', 'X6153');