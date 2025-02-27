SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND k.phonetic_code IS NOT NULL AND ci.role_id IN (2, 5, 9) AND ci.person_role_id IS NOT NULL AND mk.movie_id IN (2352227, 2421661) AND ci.nr_order = 9;