SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND mk.movie_id IN (1654258, 1822220, 1842125, 2402696, 681938, 854886) AND mc.id < 334479 AND t.phonetic_code IS NOT NULL;