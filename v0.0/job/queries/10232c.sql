SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.production_year IS NOT NULL AND mc.company_type_id = 1 AND mc.note IN ('(2002-2005) (Netherlands) (TV)') AND t.series_years IS NOT NULL;