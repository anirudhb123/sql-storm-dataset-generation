SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND cn.country_code IN ('[be]', '[li]', '[se]', '[sk]', '[tm]') AND t.episode_of_id IS NOT NULL AND t.md5sum < '325a3ba40eea6286b95c061681f933fb' AND t.title < 'Frotime' AND mk.id < 2473740;