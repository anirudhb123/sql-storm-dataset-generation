SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND k.phonetic_code IN ('B4', 'E1531', 'F2161', 'F6262', 'L315', 'N5325') AND t.id < 1075270 AND t.md5sum < '0a65fc9b5fc3253ab7dfa198daf0402d';