SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND mc.note > '(2011-) (Hungary) (TV) (M1)' AND t.title > 'Before My Eyes' AND mc.company_id > 118001 AND k.id < 71445;