SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.md5sum IN ('089a644c99c6e335d69e4ff1a1653e12', '2c049d0290ab61f7b57008a735498464', '54cc56ff5829d231b2ad9e1aeb898cb1', '9157f311745302794c781222ad426c06', '98e4ab02af24f4218d9d9b5138d831be', 'c8e2679eabf966b6440f4178fa69d7e6');