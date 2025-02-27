SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND cn.country_code IN ('[am]', '[ca]', '[cl]', '[et]', '[gg]', '[ni]', '[ph]') AND mk.keyword_id < 88242 AND cn.name > '7th Art International Agency' AND cn.id IN (105695, 97816);