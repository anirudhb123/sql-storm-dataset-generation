SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.phonetic_code > 'J6145' AND t.production_year < 2003 AND t.season_nr < 58 AND t.md5sum < '2c1eedf65e37cfd9f1ef19f1c7d1b9bb';