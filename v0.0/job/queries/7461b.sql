SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.episode_nr < 9036 AND k.phonetic_code IN ('A1635', 'C2436', 'C3126', 'C3232', 'D6362', 'E3531', 'H4253', 'N5261', 'P1231', 'W4352') AND t.production_year < 1969 AND k.id < 97985;