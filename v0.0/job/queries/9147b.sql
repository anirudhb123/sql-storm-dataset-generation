SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND n.md5sum < '613f9035bd3079a4e378c9e3122a522b' AND t.phonetic_code < 'P3424' AND n.name_pcode_nf > 'Z5265' AND k.phonetic_code < 'N2164' AND t.season_nr IS NOT NULL AND ci.role_id IN (10, 11, 2, 3, 4, 5, 9);