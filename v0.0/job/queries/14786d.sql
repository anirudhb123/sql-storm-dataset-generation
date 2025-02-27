SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND cn.md5sum > '681866cb0399b1e42e09b1441e7f9f48' AND mk.keyword_id > 126879 AND t.imdb_index = 'X' AND cn.name > 'Cybernet.it';