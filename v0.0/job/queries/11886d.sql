SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND ci.note > '(story "Wild Beasts")' AND t.episode_of_id IN (323962, 717037) AND t.season_nr IS NOT NULL AND ci.movie_id > 215417 AND n.id < 2527880 AND n.md5sum < '884b7e2eb049c5aeda30e8e1226734d2';