SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.md5sum IN ('262b369e7b7d524a93b51add6d65dc7f', '7bbad4384489247f9dbbde26c1de9b94', '9be6688851751caee96315fd96fdc9cd', 'ef920bd9aeea5fde329c2b1561644dd9');