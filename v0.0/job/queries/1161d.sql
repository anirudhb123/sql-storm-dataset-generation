SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND k.id < 1631 AND k.phonetic_code IS NOT NULL AND ci.nr_order IN (1059, 185, 2200, 313, 3263688, 43000, 529, 604, 98) AND t.season_nr < 54;