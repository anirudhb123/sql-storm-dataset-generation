SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND t.episode_nr IS NOT NULL AND t.md5sum < 'eee2348e686af88a4f090d43c9105fae' AND n.name > 'Azizbayli, Azizaga' AND k.phonetic_code < 'X5' AND n.name_pcode_nf > 'E6134' AND ci.nr_order > 2104 AND n.md5sum < '3152a975c719aaa9ecbd1ea5b8b9969d';