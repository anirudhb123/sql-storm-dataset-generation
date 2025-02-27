SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.md5sum IN ('01d35ebf4a1468c5afd27e170f79ee95', '287ee71cd191c537be04c8ce522de564', '4775aa440268de13c887330bab974f0c', '75b5605c638f60ec494a115763c20ef9');