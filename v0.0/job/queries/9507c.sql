SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.production_year = 1980 AND mi.info > 'SERIES TRADEMARK: At the conclusion of the song "One More Sleep", Kermit is seen standing alone in the street and a shooting star can been seen streaking across the sky. In many (in not all) of the Muppet movies, a shooting star goes across the sky at some point when Kermit is on.' AND mi.note LIKE '%Film%';