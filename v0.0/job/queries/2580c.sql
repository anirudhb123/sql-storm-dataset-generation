SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND k.keyword > 'reference-to-the-alamo' AND n.imdb_index IS NOT NULL AND k.phonetic_code < 'U1634' AND n.name_pcode_cf IS NOT NULL AND t.md5sum < 'a577d8eee33563751fa64bc8cad9b894';