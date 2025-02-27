SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.season_nr IN (1991, 1994, 1999, 2, 2011, 21) AND cn.country_code > '[my]' AND cn.name_pcode_nf IS NOT NULL AND mk.keyword_id < 27301 AND t.phonetic_code LIKE '%32%';