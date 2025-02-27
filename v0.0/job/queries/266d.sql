SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.md5sum IN ('63ce9999bb343d56d765055e7bff175e', '7b68c6c490297b82639cc83999abb155', '85343e5fc60d3eafe1597f101d568fdb', '8d423a88d9b21b51f00c0d166ddb4ae5', '99bea41426c36942f769cab2cf4a09f1', 'e3afeb1c4df85cec4f246cc749c3ab47', 'eae76fa4aa562daede8abcc6fc57ac12');