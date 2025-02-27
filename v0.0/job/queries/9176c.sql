SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND cn.name_pcode_sf IN ('F4541', 'G2135', 'G3', 'H6131', 'O6436', 'S2414', 'S5135') AND t.phonetic_code < 'U6216' AND t.id > 299905 AND mc.company_id > 61533 AND mk.keyword_id > 47045;