SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND mk.movie_id > 324010 AND t.episode_of_id IS NOT NULL AND t.production_year IN (1919, 1946, 1990) AND cn.md5sum > 'b32f99b3f93d5378c3f6c52de6029367';