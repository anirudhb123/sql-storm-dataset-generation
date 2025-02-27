SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND mc.movie_id < 2203021 AND t.phonetic_code IN ('G6465', 'J5142', 'L4354', 'S2421', 'X3135') AND cn.name LIKE '%Film%';