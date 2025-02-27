SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.season_nr IN (10, 1984, 2, 2007, 2013, 28, 42, 56, 63, 8) AND t.kind_id IN (0, 2, 3, 4, 6, 7) AND k.phonetic_code < 'N565';