SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND cn.name IN ('Black Dot Media', 'JBTV Chicago', 'Micky Productions', 'Naked Sky Entertainment', 'O.R.P.', 'Tagstorm Pictures', 'Tim Devitt Productions', 'Édition Films Champion');