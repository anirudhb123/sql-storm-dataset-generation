SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND mc.note IS NOT NULL AND t.md5sum > '93258c044f09c1d706c67330ae9a4554' AND mk.movie_id < 2417323 AND t.title < 'En busca de un muro' AND mc.company_id IN (11850, 134059, 140321, 160606, 178520, 30080, 55805);