SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND cn.id IN (170883, 221714, 229117, 30119, 63981, 7100) AND cn.name > 'Lucernafilm - Gama' AND k.keyword > 'crazy-doctor';