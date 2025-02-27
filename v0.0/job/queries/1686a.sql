SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.md5sum IN ('34bcd3ac52396248dd371849d29dfb45', '42cff3ec5d3b61fa6068a72917ec8470', 'ac3b319a24642c641769216d19b9eb13', 'c5a334f56819a3b2af110a4543e4cf6f', 'e586ef0402009e3f812e93eb8f1b9da9', 'f4c9db06b518a9f9cd243642131e0c4a', 'f6828e92475616e38871297491d1ff74');