SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.title > 'Rapsodiya v byalo' AND t.id > 36635 AND mk.keyword_id = 21923 AND t.md5sum < '13cbf48fbbbc7c126ec752f8d5728506';