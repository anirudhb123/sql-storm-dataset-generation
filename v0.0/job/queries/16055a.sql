SELECT min(n.name) AS member_in_charnamed_movie
FROM cast_info AS ci, company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, name AS n, title AS t
WHERE n.id = ci.person_id AND ci.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.movie_id = mc.movie_id AND ci.movie_id = mk.movie_id AND mc.movie_id = mk.movie_id
AND n.name_pcode_nf IS NOT NULL AND cn.md5sum IN ('0627102aba6410f380b8f3c434e8fdfb', 'b2f6e1c7f0876a02487d02eb8e6536dc', 'b502a040c86ba494dfb53d66e4e5a01e', 'ca51867f05d1eef9a745a183fea2a58f');