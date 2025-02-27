SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND mk.id > 3577022 AND mc.note < '(1982) (USA) (video) (video 2000)' AND mc.id > 468242 AND cn.md5sum < '8da87ef77550cb81ba541ebae82a2929' AND t.kind_id IN (0, 1, 2, 3, 4, 7) AND t.imdb_index < 'XXII';