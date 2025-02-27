SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND mk.keyword_id < 2214 AND t.title LIKE '%Sweet%' AND t.phonetic_code < 'L453' AND mc.company_type_id > 1 AND t.id < 1129434;