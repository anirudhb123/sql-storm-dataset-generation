SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND t.series_years IS NOT NULL AND mk.id < 363556 AND n.name_pcode_nf IS NOT NULL AND k.phonetic_code > 'D4326' AND t.title < 'Matloub zawja fawran' AND n.md5sum > 'b67c2a2eff76ac282ddec0564cc985fc';