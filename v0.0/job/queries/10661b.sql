SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND cn.name LIKE '%Productions%' AND t.imdb_index IN ('III', 'IV', 'IX', 'VI', 'XII', 'XIV', 'XV', 'XVII', 'XVIII', 'XXIII') AND mc.id < 2317844;