SELECT min(n.name) AS member_in_charnamed_movie
FROM cast_info AS ci, company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, name AS n, title AS t
WHERE n.id = ci.person_id AND ci.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.movie_id = mc.movie_id AND ci.movie_id = mk.movie_id AND mc.movie_id = mk.movie_id
AND t.title > 'Joy to the World/Snow Business' AND t.season_nr > 18 AND k.phonetic_code > 'O2532' AND t.production_year IN (1918, 1928, 1938, 1943, 1964, 1982, 2014, 2015, 2017, 2019);