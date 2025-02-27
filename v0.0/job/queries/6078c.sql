SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND t.kind_id < 7 AND k.phonetic_code < 'V3525' AND t.md5sum < '3e11253b130432ff2ed2aca6cdb5a75b' AND k.id > 51928 AND mk.keyword_id IN (131392, 14198, 1748, 23264, 28894, 41665, 53519, 67283, 77124, 87953) AND ci.movie_id > 1035560;