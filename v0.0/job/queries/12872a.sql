SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND cn.md5sum < '163f0c1e32aa6017f379885cd46b5211' AND t.production_year IS NOT NULL AND k.keyword IN ('city-railway', 'roman-bath');