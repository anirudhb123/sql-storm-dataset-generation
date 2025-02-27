SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.phonetic_code IN ('A4563', 'J5234', 'K5141', 'N6515', 'P4613', 'S5414', 'U2512') AND mi.id > 9015868;