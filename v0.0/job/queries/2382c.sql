SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND n.md5sum IN ('45d35c15efd019f888a732e154fd2202', '73e59439eb16697d9426742afdc7287d', 'a514872d34bdd5252b81b240149cfe4a', 'ab74585f1c42de561939d778d2111cff', 'b5398b193895e7af83ca510364849dfe', 'be42dab163a3c8d156588c0f15bca529') AND k.keyword < 'powderpuff-girl';