SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.imdb_index IS NOT NULL AND k.keyword > 'porno-movie' AND t.phonetic_code < 'G313' AND t.production_year IS NOT NULL AND t.md5sum < '4d878f0f80bca88d68b73bb748424e1e' AND mi.movie_id < 2226903;