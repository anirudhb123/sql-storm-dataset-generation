SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND cn.md5sum IN ('6196eaed3c34b10480612d83f737fe2b', '74e2b12f2faabc18a2deb6dbb038d478', 'a75a3a23bc060257f8e8d86e9d07f656', 'f8287ab5bdf8fdc111e740d6e3caa0fd', 'f8c9435c8bf82619c1aa0911f37a3b3b');