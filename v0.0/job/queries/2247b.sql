SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND mk.movie_id > 2159969 AND k.keyword < 'reference-to-shirley-bassey' AND mi.info = '$32,921 (USA) (21 October 2007)' AND k.phonetic_code LIKE '%23%';