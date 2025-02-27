SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND mk.keyword_id IN (120606, 125077, 129273, 15987, 33225, 68416, 75210, 98956) AND k.keyword < 't800' AND mk.id > 1062456;