SELECT min(n.name) AS member_in_charnamed_movie
FROM cast_info AS ci, company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, name AS n, title AS t
WHERE n.id = ci.person_id AND ci.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.movie_id = mc.movie_id AND ci.movie_id = mk.movie_id AND mc.movie_id = mk.movie_id
AND mk.movie_id IN (1262441, 1443772, 1708119, 1929105, 2124649, 2278286, 2431893, 2513929) AND k.phonetic_code < 'A24' AND t.production_year > 1937 AND cn.name_pcode_nf IS NOT NULL;