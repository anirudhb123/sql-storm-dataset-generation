SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND ci.id < 5903361 AND n.id < 68708 AND ci.person_role_id < 515293 AND k.id < 48567 AND n.name_pcode_cf > 'S3264' AND t.phonetic_code > 'Y5236';