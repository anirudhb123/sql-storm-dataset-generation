SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND t.md5sum IN ('22b38cee8d904779e16523fcdd9f40d3', '3e71952175f75ada1099ba5179976513', '611186692876fda3468932e4a1626e29', '89bf76d0a1be99a7425964991b1f588c', '8ad6f59e44bc93120386305eec140fa0', '9e239b0fcd9f7ab2a7d37aa5513f7082', 'baaae1f22335c1f0eb5fae17d7333c4d', 'de242eeda46cd2e9d9c6fed87aaee7f9');