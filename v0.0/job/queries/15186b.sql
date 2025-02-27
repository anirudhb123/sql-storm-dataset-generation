SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND n.gender = 'f' AND ci.note > '(as Ernst Sladek)' AND t.md5sum < 'd52e5c85eebae2a84d21b7d15f2a7f17' AND t.phonetic_code < 'T5152' AND n.surname_pcode > 'R263' AND n.name > 'Paul, Danny' AND t.season_nr IS NOT NULL;