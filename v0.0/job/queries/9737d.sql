SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND mc.id > 1311085 AND mc.company_id > 11698 AND t.md5sum < 'b28d333a6e020d1c4478386b570c641f' AND mk.id < 82171;