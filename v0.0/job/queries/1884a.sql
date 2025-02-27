SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND k.keyword LIKE '%cross%' AND mi.info_type_id IN (4) AND t.md5sum < '7e4e9de4715a6b48436bdfd3f43af851' AND t.kind_id < 4;