SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.id IN (125021, 1600084, 2028058, 2179298, 2326696, 463007) AND mi.note > '(including commercials) (213 episodes)';