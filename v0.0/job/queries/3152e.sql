SELECT min(n.name) AS member_in_charnamed_movie
FROM cast_info AS ci, company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, name AS n, title AS t
WHERE n.id = ci.person_id AND ci.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.movie_id = mc.movie_id AND ci.movie_id = mk.movie_id AND mc.movie_id = mk.movie_id
AND n.surname_pcode IN ('B13', 'C162', 'I363', 'Q612', 'S413', 'V54', 'Y135', 'Z354') AND cn.md5sum < '2f5db6c5aa4b756c7afd66c939a70ecf' AND t.season_nr < 6 AND cn.country_code IS NOT NULL;