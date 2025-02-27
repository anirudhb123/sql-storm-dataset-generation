SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND mi.info > 'Estonia:6' AND t.title IN ('Doula! The Ultimate Birth Companion', 'Latent Sorrow', 'Love Is All Around, or Is It?', 'The Beastie Boys: Hello Nasty Live', 'Tong oldidan') AND k.phonetic_code > 'T16';