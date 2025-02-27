SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND k.keyword = 'injury-from-a-car-crash' AND mk.keyword_id > 9114 AND t.md5sum < '2f6c6dd5284bf1360c2e533ad33bee99' AND t.phonetic_code IS NOT NULL;