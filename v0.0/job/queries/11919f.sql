SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND mk.id IN (1829187, 2915199, 2920885, 4243579) AND n.id > 1360976 AND n.md5sum < '4cecc151cc542fb3dfec0cf8251b2531' AND t.title < 'Nix im Leben ist umsonst';