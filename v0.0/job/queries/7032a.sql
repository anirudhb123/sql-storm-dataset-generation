SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.episode_of_id IN (1011188, 1170470, 1396172, 1580523, 198700, 291665, 65475, 838249) AND mi.info_type_id < 102 AND t.phonetic_code IS NOT NULL AND k.keyword < 'remodernist' AND k.phonetic_code LIKE '%35%';