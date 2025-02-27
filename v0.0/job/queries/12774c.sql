SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.md5sum IN ('3142ffbdc149e5480be05b0a4e851af4', 'c794740d016f60732680b659db64284d', 'e5fc28c0b84e66c982b2fbfbe3ed38f9') AND mi.info > 'Ireland:10 May 2005';