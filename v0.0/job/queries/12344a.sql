SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.md5sum > '6d1ce9828944028b6e5753caeeff1c96' AND cn.id > 54270 AND mc.company_id IN (11185, 116436, 130540, 146914, 174693, 203893, 216645, 35885, 64729, 95634);