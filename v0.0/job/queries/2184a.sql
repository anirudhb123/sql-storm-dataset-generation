SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND n.name < 'Joy, Julian' AND n.name_pcode_nf > 'I1416' AND ci.person_id IN (1380469, 1532816, 2267925, 3084511, 3149804, 3250023, 3505111, 3981517, 671340, 842624);