SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.episode_of_id IS NOT NULL AND cn.name_pcode_nf IS NOT NULL AND k.keyword < 'trevi-fountain' AND t.md5sum > '3f971712bb1448839e4df95883d58641' AND cn.md5sum IS NOT NULL;