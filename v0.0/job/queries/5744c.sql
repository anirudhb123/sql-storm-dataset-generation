SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND mk.movie_id > 2054236 AND cn.md5sum > '25a022dfab19f4012ac6668c66904f39' AND t.phonetic_code LIKE '%P23%';