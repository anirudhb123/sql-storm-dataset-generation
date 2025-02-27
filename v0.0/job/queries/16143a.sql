SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND t.production_year > 1920 AND k.phonetic_code IS NOT NULL AND n.name_pcode_nf = 'F5323' AND ci.note < '(as Sen Rand Paul)' AND n.gender IN ('f', 'm') AND mk.keyword_id < 89451;