SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.id < 661814 AND t.phonetic_code IN ('E5316', 'E652', 'G2452', 'G3623', 'J1643', 'K1353', 'K4245', 'M4232', 'T4643') AND t.episode_nr IS NOT NULL;