SELECT min(n.name) AS member_in_charnamed_movie
FROM cast_info AS ci, company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, name AS n, title AS t
WHERE n.id = ci.person_id AND ci.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.movie_id = mc.movie_id AND ci.movie_id = mk.movie_id AND mc.movie_id = mk.movie_id
AND t.md5sum IN ('2a6ebef019840614541e16718c36fc3f', '40c57265afb9ed4a484ebea741c51502', '835ba44837f4d53d01b767989c2e8621', 'b50f690bd100a2d98dcc329bfaa716e8');