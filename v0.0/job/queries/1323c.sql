SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND mi.id > 3141537 AND t.phonetic_code IN ('A5353', 'A6161', 'C5215', 'G3415', 'I2135', 'N3524', 'Q6513', 'R6412', 'T6454', 'W631') AND t.episode_of_id IS NOT NULL AND mk.keyword_id < 54145;