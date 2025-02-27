SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.episode_of_id IS NOT NULL AND t.title IN ('El fin es el principio', 'Ercument Cozer Geri Donuyor!', 'Fushigi no mori no shirayukihime', 'Porridge Art', 'Ta megala kamakia ton travesti', 'Texas Jack', 'The Dental Dynamiter', 'The License', 'W.O.W.1');