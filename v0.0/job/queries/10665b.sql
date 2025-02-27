SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND k.keyword IN ('altwasser-river', 'bionicle', 'climbing-on-a-piano', 'curtains', 'death-on-custody', 'lingerie-slip', 'lower-ninth-ward', 'milk-bottlecap', 'reference-to-stuart-sutcliffe') AND ci.person_id < 409410;