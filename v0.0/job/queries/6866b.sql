SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND mk.keyword_id < 47553 AND t.md5sum < 'ec0361c1adf7deb77634669ddaea4368' AND cn.name_pcode_sf IN ('E5216', 'H6456', 'K1251', 'T3242');