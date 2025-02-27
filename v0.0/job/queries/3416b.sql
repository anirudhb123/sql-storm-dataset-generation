SELECT min(n.name) AS member_in_charnamed_movie
FROM cast_info AS ci, company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, name AS n, title AS t
WHERE n.id = ci.person_id AND ci.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.movie_id = mc.movie_id AND ci.movie_id = mk.movie_id AND mc.movie_id = mk.movie_id
AND mc.note IS NOT NULL AND k.phonetic_code = 'G5635' AND n.imdb_index IS NOT NULL AND ci.nr_order IN (1107, 1110, 1163, 23100, 285, 452, 50, 612, 704) AND ci.person_role_id > 1951240;