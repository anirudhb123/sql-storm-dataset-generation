SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND cn.name_pcode_nf < 'S1361' AND cn.md5sum IS NOT NULL AND t.id < 2190138 AND t.season_nr IS NOT NULL AND k.keyword > 'first-contact' AND cn.name < 'AllAmericanMilitary';