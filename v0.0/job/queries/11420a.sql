SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.md5sum IN ('15e75572a700825948d76280742191e5', '873ce1d89c3b703ad3089297a3271dbd', '88d893784438207f2347f20f7079daab', '9299379cc0e77600e1b5db0ba99c15df', '987c76a6996628a443f59a1d115c75a8', 'c3f90b49c850236691908237bbcc9df4', 'c9160e41234a9cc0e77b470aacd2a642') AND cn.country_code IS NOT NULL AND cn.name_pcode_sf LIKE '%F%';