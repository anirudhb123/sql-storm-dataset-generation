SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.production_year > 1920 AND cn.md5sum > '7bfd1364fc2809b3d431a79fbc0711bd' AND cn.id IN (13132, 132108, 138525, 187449, 80602);