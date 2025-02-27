SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.md5sum < '9dd1f05b2cadf51fd37d6826b4039112' AND t.production_year IS NOT NULL AND mi.info LIKE '%Sweden:9%' AND t.episode_of_id > 95932;