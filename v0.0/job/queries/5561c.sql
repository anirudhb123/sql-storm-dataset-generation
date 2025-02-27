SELECT min(n.name) AS member_in_charnamed_movie
FROM cast_info AS ci, company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, name AS n, title AS t
WHERE n.id = ci.person_id AND ci.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.movie_id = mc.movie_id AND ci.movie_id = mk.movie_id AND mc.movie_id = mk.movie_id
AND n.md5sum IN ('8e9cd4776a5ea92f2de5534931aadabc', '998f35a806ccf67cc5f5211bfea9b923', 'a5ee86adf9a068945e37e6e8125961f4', 'd15a8f632087af39b17361fdacd48c0c');