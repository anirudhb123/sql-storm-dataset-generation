SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.md5sum > '12bb24d8f88d56391c0c462dad3f787f' AND t.phonetic_code IN ('A324', 'A6261', 'B5354', 'C363', 'J3235', 'S2136', 'S3164', 'V6434', 'X5215', 'Z363');