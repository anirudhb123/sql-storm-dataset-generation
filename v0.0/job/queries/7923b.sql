SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.md5sum < 'c9a29c07b42b140bcae60763e98c18ed' AND t.production_year = 1939 AND mk.keyword_id < 122354 AND t.kind_id > 0;