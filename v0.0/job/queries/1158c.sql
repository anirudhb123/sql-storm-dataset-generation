SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.id IN (1692496, 1855783, 1925100, 1932368, 2184077, 2189936, 453778, 646520) AND k.phonetic_code IS NOT NULL;