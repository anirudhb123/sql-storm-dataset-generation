SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND mc.company_id < 140348 AND k.phonetic_code LIKE '%6%' AND mk.keyword_id < 83754 AND t.imdb_index > 'VII' AND cn.name_pcode_nf IS NOT NULL AND t.md5sum > '8abc4c645fa0efa7ac0980a3d519cc33';