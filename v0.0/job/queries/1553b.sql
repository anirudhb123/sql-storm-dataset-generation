SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND mk.id < 877121 AND mc.company_type_id IN (1, 2) AND mc.note < '(1998) (Russia) (TV)' AND mk.keyword_id < 26786 AND k.phonetic_code IN ('A634', 'A6514', 'N1', 'S5423') AND t.phonetic_code < 'O316' AND t.series_years IS NOT NULL AND mc.id < 2210528;