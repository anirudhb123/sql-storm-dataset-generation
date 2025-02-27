SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND mk.keyword_id IN (107097, 109064, 130215, 16503, 80920) AND t.title LIKE '% Part 1%' AND t.md5sum IS NOT NULL AND mi.info > 'Sonya Bartow: I love you too, Paul... in my own funny way.';