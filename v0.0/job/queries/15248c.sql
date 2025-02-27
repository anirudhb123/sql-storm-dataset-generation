SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND k.keyword IN ('buttons', 'clermont-ferrand', 'cyberculture', 'end-love-affair', 'female-hacker', 'jewell', 'the-falcon', 'willingness') AND k.id < 108828 AND k.phonetic_code < 'R125';