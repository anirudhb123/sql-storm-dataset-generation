SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.title IN ('(#1.4691)', '2 Girls im Spermaexperiment', 'Back to Even', 'Barber Yoshino', 'Hero the Great', 'Karaoke Revolution Volume 2', 'Le fauteuil 47', 'Meeting Halfway', 'Rivertown') AND cn.name > 'Goteborg Film Fund';