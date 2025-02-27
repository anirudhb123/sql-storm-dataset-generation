SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND mk.keyword_id < 130293 AND t.episode_nr IN (10930, 12505, 13299, 13372, 15031, 15407, 2173, 3793, 6018, 8622);