SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.production_year IN (1893, 1900, 1929, 1957) AND t.md5sum > 'b0016c09834e5e0f26420da58448784a' AND mi.movie_id < 1235667 AND t.episode_nr < 5890 AND t.phonetic_code > 'J4625';