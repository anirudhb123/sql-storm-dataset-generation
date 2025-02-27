SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND mc.note = '(2002) (Finland) (theatrical) (with Norwegian subtitles)' AND t.production_year IS NOT NULL AND cn.name_pcode_nf > 'B3131' AND cn.name_pcode_sf > 'J532';