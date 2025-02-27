SELECT min(n.name) AS member_in_charnamed_movie
FROM cast_info AS ci, company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, name AS n, title AS t
WHERE n.id = ci.person_id AND ci.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.movie_id = mc.movie_id AND ci.movie_id = mk.movie_id AND mc.movie_id = mk.movie_id
AND n.md5sum IN ('2b5212c7077f696c5813abc229bb29fe', '60484c8955cbdcab0b4a7b2156a87ffb', '9c4363d85d98c136713b11d5f0826bfb', 'fb922c9d3b52ee87bdd1d98e6d311fa7');