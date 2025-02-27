SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND ci.person_role_id > 158749 AND k.keyword IN ('blue-sea-lake', 'buick-automobile', 'claviceps-purpurea', 'farm-hand', 'imas', 'letter-from-president', 'memo', 'model-railroad', 'photon', 'summit-meeting') AND mk.id < 2266026;