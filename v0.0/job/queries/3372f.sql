SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND t.series_years IN ('1956-1960') AND n.surname_pcode < 'S251' AND n.name_pcode_cf IS NOT NULL AND ci.note IS NOT NULL AND t.production_year IS NOT NULL AND ci.person_id < 2253987;