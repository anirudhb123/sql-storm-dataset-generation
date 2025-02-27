SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.title > 'Edge of Reality: Illinois UFO, January 5, 2000' AND k.keyword > 'woman-shot' AND mc.id > 2413942 AND t.phonetic_code < 'F1632' AND t.production_year > 1941;