SELECT min(n.name) AS member_in_charnamed_movie
FROM cast_info AS ci, company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, name AS n, title AS t
WHERE n.id = ci.person_id AND ci.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.movie_id = mc.movie_id AND ci.movie_id = mk.movie_id AND mc.movie_id = mk.movie_id
AND n.imdb_index IN ('CLXXXVIII', 'CVI', 'CVII', 'CXLII', 'CXLVII', 'LXXX', 'XCIII', 'XL') AND ci.role_id IN (1, 11, 4, 5, 7, 8) AND k.keyword < 'sun-grazing-comet';