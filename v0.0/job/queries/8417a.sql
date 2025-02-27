SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND mk.id IN (1011700, 1359967, 1706504, 1754119, 2487507, 2572035, 3578023, 3751601, 4315835, 938026) AND t.md5sum IS NOT NULL;