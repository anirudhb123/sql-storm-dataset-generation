SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND mc.note IN ('(1977) (West Germany) (video) (dubbed version)', '(1998) (Nigeria) (video)', '(2006) (USA) (DVD) (subtitled)', '(2009) (Netherlands) (TV) (season 1)') AND t.md5sum > 'c1b3fa76d58ff2ebc2c562e6c53be772';