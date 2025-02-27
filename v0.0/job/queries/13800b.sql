SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND k.phonetic_code IN ('B412', 'C4616', 'E6351', 'G1253', 'J2612', 'L14', 'M463', 'R2531', 'S5616') AND t.md5sum IS NOT NULL AND n.md5sum > 'be35419c7f501fc5a3cbb55d840b7803';