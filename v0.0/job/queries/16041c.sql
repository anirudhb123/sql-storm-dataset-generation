SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND mk.id > 1376173 AND mi.note IS NOT NULL AND t.kind_id IN (4) AND k.keyword > 'revolving-light' AND t.md5sum < '8eb918afee02eef3491fe2dc83d741c6';