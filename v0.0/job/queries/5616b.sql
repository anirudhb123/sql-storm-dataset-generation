SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND t.phonetic_code > 'Q4256' AND k.keyword IN ('department-store-santa', 'evil-soul', 'hair-salon', 'irish-dancer', 'paper', 'reference-to-robert-powell', 'reference-to-samuel-goldwyn', 'sex-positions', 'sex-with-therapist', 'tree-engraving') AND t.md5sum IS NOT NULL AND t.episode_of_id > 585227;