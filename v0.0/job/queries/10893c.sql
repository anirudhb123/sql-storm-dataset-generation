SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.md5sum < '595472b1b78cb86ee46abe9495938d03' AND mi.movie_id > 92676 AND t.phonetic_code LIKE '%Z63%' AND k.phonetic_code IS NOT NULL AND mi.info_type_id > 104;