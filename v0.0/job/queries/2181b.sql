SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND k.phonetic_code > 'C6521' AND t.md5sum IS NOT NULL AND t.episode_of_id IN (1138598, 1260532, 1395426, 1583396, 536576, 554136, 632976, 695908, 77315);