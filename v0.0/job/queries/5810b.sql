SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.phonetic_code < 'O1451' AND t.md5sum < '4481aa01d3f740c27b9c3b5ce9add086' AND t.production_year IS NOT NULL;