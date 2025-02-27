SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.phonetic_code IS NOT NULL AND k.phonetic_code IN ('A1352', 'H3141', 'N3462', 'P421', 'S5313', 'S6152', 'Y4263') AND t.episode_of_id < 1129935;