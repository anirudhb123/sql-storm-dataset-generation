SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND t.md5sum IN ('052470b58aab0e70ec3b95a5b706e0fa', '39aae8aabe77d8c4c8e1d1da278e4464', '43a8b8b8008b1be70048cd931a6f4ef7', '784825827a0255f1d248a6935cc86fcd', '9c14e0239a7aef8c7f9ad08c89ddcf58') AND mk.keyword_id < 28195 AND ci.role_id > 9;