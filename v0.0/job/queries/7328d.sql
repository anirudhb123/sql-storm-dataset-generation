SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND cn.name_pcode_nf IS NOT NULL AND t.production_year < 1995 AND t.phonetic_code IN ('C5454', 'D1246', 'D1526', 'E2142', 'M5164', 'O1612', 'S356', 'W2625') AND t.md5sum < '9100c6c5fcb09bc7d691ac06b7d4f3db';