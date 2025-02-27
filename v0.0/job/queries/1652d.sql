SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND cn.name_pcode_sf LIKE '%B356%' AND cn.id > 128729 AND cn.md5sum < 'f013fc48c7e649be38c5ae6b93535331' AND t.kind_id IN (0, 4, 7);