SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.imdb_index IN ('III', 'V', 'VI', 'X', 'XII', 'XIII', 'XV', 'XVIII', 'XXII', 'XXIII') AND mc.note < '(2006) (Philippines) (theatrical)' AND t.phonetic_code IS NOT NULL AND k.phonetic_code LIKE '%3%';