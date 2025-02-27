SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.phonetic_code > 'M2614' AND k.keyword IN ('black-housewife', 'peter-lawford-spoof', 'roue', 'soccer-cleats', 'spilled-wine', 'viking-helmet', 'washed-up-star') AND mi.info LIKE '%guys.%';