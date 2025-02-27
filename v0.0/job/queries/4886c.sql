SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.imdb_index < 'XXII' AND cn.md5sum > '8e329cc7b921e78e5fb45250a1d743d0' AND mc.movie_id > 437374 AND mk.keyword_id < 47934;