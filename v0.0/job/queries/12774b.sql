SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.md5sum < '54d9443e364a79bb93f1ddd436c5ef3c' AND t.imdb_index < 'X' AND mk.keyword_id IN (40976, 41074, 60572);