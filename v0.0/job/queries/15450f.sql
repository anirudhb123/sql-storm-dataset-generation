SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND t.phonetic_code < 'B4212' AND t.season_nr < 23 AND t.episode_of_id IN (1302688, 1507295, 1549651, 31059, 586852, 60831, 634633, 746459, 856725, 913626) AND ci.id > 15763660;