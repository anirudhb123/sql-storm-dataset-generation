SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND mi.info > '$54,079 (UK) (14 June 2009) (5 screens)' AND mi.id > 3241343 AND t.title IN ('Barely Legal 112', 'Diario de un skin', 'Dva bijela kruha', 'Friends and Enemies, Vacation Land and Squirrel Food', 'Genhachî to osûmi', 'Peachy Delicious', 'The Eighteen Carat Virgin', 'Toot Toot!/To Bee or Not to Bee') AND t.kind_id > 0 AND mk.id > 3176892;