SELECT min(n.name) AS member_in_charnamed_movie
FROM cast_info AS ci, company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, name AS n, title AS t
WHERE n.id = ci.person_id AND ci.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.movie_id = mc.movie_id AND ci.movie_id = mk.movie_id AND mc.movie_id = mk.movie_id
AND ci.id > 29256520 AND n.name_pcode_cf IS NOT NULL AND cn.id > 30373 AND k.phonetic_code < 'S3145' AND ci.role_id > 7 AND t.episode_nr < 8415 AND mc.company_type_id > 1;