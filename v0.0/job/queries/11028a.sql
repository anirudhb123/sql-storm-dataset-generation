SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND n.imdb_index < 'XLVII' AND t.phonetic_code IN ('B2525', 'E215', 'T6263', 'T6312', 'W1545') AND t.episode_nr < 5077 AND mk.keyword_id < 13628;