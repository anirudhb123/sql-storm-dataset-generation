SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND t.md5sum > '67385edbd32e842c0b63be8395f50bd4' AND k.phonetic_code IN ('A3636', 'J625', 'M4135', 'S3514', 'X142') AND t.season_nr < 34;