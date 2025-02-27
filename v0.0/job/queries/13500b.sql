SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND mi.info_type_id > 78 AND t.phonetic_code < 'L2363' AND t.md5sum > '2776ce0af583bfaf66370bf293d49a98';