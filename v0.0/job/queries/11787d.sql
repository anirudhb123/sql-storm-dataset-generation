SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND ci.id < 32476527 AND n.name_pcode_nf IS NOT NULL AND ci.nr_order < 343 AND k.phonetic_code < 'L1243' AND mk.keyword_id > 17882 AND ci.role_id > 7;