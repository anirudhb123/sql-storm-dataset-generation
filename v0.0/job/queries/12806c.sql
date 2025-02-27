SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND cn.md5sum IN ('23a417b6862b84f82d821d060840b8d6', '3a9316b14353bae34b943cfaeb429af4', '595305dbb015de89ef8c36e350a01463', '8fb6aa06d3c57de467780a7eba8eb428', 'cb2c2d692137cdafcdd9e586ec2a5ba5', 'cd623728db87ca7f2a74a4cf8088d7f7', 'ee9abaa80b6fe20f409df90a35cde863');