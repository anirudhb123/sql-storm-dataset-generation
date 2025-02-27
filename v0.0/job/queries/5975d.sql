SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.season_nr IS NOT NULL AND k.phonetic_code LIKE '%363%' AND t.md5sum < '24eb2626342204ead0329d5f1e4f83d5';