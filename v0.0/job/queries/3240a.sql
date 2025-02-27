SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND n.name_pcode_cf > 'I2635' AND t.series_years > '1998-2006' AND k.phonetic_code IS NOT NULL AND n.gender IN ('f') AND t.md5sum > '970cc1088f44adb1a698243d87b21306';