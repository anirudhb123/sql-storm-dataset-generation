SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND cn.md5sum IN ('2e19cdac2b958aae72f99616c14b8733', '68cd13c47c9239380c38ac3158f451b8', 'a34a8211b52af6ff0ba5c5c444e0efed', 'a543f35d0595401caf757eb8af3e5521', 'e7157212d4d432469fe26a2552500be7');