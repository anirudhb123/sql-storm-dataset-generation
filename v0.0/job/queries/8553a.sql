SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND mk.id IN (1703603, 1928112, 2214034, 237165, 3132036, 498912, 712346, 831093) AND n.surname_pcode < 'U156' AND t.production_year > 1898;