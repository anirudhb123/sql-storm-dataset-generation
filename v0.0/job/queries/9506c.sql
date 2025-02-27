SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.kind_id > 0 AND mc.movie_id < 1676521 AND cn.md5sum < 'f024897bd49cebc186bd91f71530901d' AND cn.country_code < '[be]' AND t.production_year < 1940;