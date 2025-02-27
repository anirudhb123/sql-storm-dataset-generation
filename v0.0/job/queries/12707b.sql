SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.production_year IS NOT NULL AND cn.country_code > '[er]' AND cn.name_pcode_sf IS NOT NULL AND mc.company_id < 153667 AND t.imdb_index > 'XVII' AND cn.md5sum < 'e915259a7ccc9b05252cfb1cc45a53cc';