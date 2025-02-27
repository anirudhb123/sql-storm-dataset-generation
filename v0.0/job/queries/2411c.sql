SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.title > 'Higashi no Eden Gekijoban I: The King of Eden' AND cn.name_pcode_nf IS NOT NULL AND cn.country_code IN ('[bo]', '[dm]', '[id]', '[pm]', '[ve]', '[vg]');