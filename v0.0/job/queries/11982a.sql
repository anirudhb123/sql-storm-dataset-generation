SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND mk.keyword_id < 107848 AND t.episode_nr < 13295 AND k.phonetic_code IS NOT NULL AND k.id < 20089 AND mi.movie_id < 1638257 AND mi.note > '(Pre-credits Sequence)' AND t.phonetic_code = 'T4141' AND t.md5sum < 'f2b48de4a321b0a034ebfaedd86c9619';