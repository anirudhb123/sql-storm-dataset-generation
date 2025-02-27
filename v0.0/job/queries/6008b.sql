SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.kind_id < 4 AND t.md5sum < 'fa128bd7ee377f3b43cb7940d65e3e34' AND mc.company_type_id > 1 AND k.phonetic_code LIKE '%126%' AND k.keyword < 'mule-riding';