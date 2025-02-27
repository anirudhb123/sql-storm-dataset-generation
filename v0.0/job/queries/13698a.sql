SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.title < 'Podróz do Moskwy' AND mi.info > 'Cheryl: [possessed] Soon all of you will be like me... And then who will lock you up in a cellar? [cackles]';