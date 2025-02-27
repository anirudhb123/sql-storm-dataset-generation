SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND t.episode_nr IN (1126, 11462, 12737, 13220, 217, 2495, 3324, 8769, 9498) AND n.surname_pcode < 'E16' AND k.phonetic_code > 'B2526' AND t.phonetic_code IS NOT NULL;