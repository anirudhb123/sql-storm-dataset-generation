SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND k.phonetic_code > 'A5234' AND mc.note > '(2011) (worldwide) (all media) (except Greece and Cyprus)' AND t.season_nr = 26 AND t.phonetic_code IS NOT NULL;