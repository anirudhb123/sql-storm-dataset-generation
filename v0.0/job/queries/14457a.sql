SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.md5sum IN ('0669bb2d810159c1c4eddd80199da236', '49315cd69d4dbadfe2352b97dcf32039', '4b35b2f0cbdb5052efa765462fefc6cb', '7ccc8b7f25acf151423dec348c96156a', 'a8fdd6b9aba77d2a74fa7d6301a7c7a9', 'ab0a1931d2f4c590935eb6542b8c09c1', 'ac11fa8e184696aeac49d27fe34d9700', 'b7e0910241775b1bde065b64a5d48e91', 'c892915ef7e79abe3107a0f3965b18ba', 'e6f495c2f165d8c9f729864514cd3916');