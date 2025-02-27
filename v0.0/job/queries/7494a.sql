SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.phonetic_code IS NOT NULL AND mi.movie_id > 1871065 AND mi.info_type_id IN (108, 12, 40, 57, 63, 8, 80, 85, 95, 97) AND t.title IN ('Cyberslut', 'Manbeast! Myth or Monster?', 'The Art of Attitude/The Art of Revenge', 'The World View of Noam Chomsky');