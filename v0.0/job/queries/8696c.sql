SELECT min(n.name) AS member_in_charnamed_movie
FROM cast_info AS ci, company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, name AS n, title AS t
WHERE n.id = ci.person_id AND ci.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.movie_id = mc.movie_id AND ci.movie_id = mk.movie_id AND mc.movie_id = mk.movie_id
AND k.phonetic_code IS NOT NULL AND n.surname_pcode IN ('A314', 'B1', 'G251', 'O364', 'O513', 'U356', 'V35') AND t.imdb_index < 'IV' AND n.name_pcode_cf IS NOT NULL;