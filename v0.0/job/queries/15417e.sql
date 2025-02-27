SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND k.phonetic_code > 'S1643' AND n.md5sum < 'df4dcc1174d4c0f4e24b7d4deef0f022' AND n.id < 1199748 AND k.id < 122098 AND t.series_years IN ('1893-1894', '1951-1959', '1954-2006', '1958-1979', '1959-1990', '1970-1980', '1974-2013', '1981-1983', '1999-2012') AND ci.role_id > 8;