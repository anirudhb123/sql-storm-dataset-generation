SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.phonetic_code IN ('D2524', 'I5324', 'M613', 'U5254') AND t.md5sum < 'd8824f7976242358e0371cc5f91aed4d';