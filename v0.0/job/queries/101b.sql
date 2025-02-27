SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND cn.country_code < '[zm]' AND mk.id IN (1054977, 1737630, 2085013, 2637278, 3312542, 3445953, 3533692, 4317347, 838931) AND mc.company_type_id IN (1, 2) AND t.kind_id IN (3);