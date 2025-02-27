SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND ci.person_role_id IN (1885440, 2080339, 2276567, 2413142, 2479323, 2661651, 3020935) AND mk.movie_id > 582135 AND t.phonetic_code > 'U356' AND k.phonetic_code < 'F5423';