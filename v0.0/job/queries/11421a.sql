SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.season_nr < 24 AND t.phonetic_code IN ('A6432', 'D6421', 'N5131', 'P2456') AND mi.id < 3626045 AND t.episode_of_id < 1440080 AND mi.note IS NOT NULL;