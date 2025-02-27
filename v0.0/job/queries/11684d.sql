SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND k.keyword > 'foot-seduction' AND t.kind_id IN (1, 3, 7) AND t.imdb_index IN ('II', 'IV', 'XIII', 'XVI', 'XVIII', 'XXI', 'XXIV');