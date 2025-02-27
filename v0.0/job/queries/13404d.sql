SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND n.md5sum IN ('1def0f925c325a620062cff42cab0bb6', '23229516896f828e00a7b56ff284e3e5', '9f9175ba2f4d9c829ed155380c3fb632', 'a48c9cabb27b93674833928e43199c3d', 'cd58056ba2bf2a4a060a83f1774a7c3b', 'e7327cec8a52d5a5dcbc531633f07fe0');