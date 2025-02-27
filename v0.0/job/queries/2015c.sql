SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.imdb_index = 'XXIII' AND t.production_year IS NOT NULL AND t.md5sum < 'cd9e7bd1ffa9897fc96a6c8b496dfe9b' AND k.keyword < 'time-travelling-machine';