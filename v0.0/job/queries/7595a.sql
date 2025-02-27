SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND t.title IN ('(1978-05-27)', 'Last Cry for Katrina', 'Meiken Fîbâ no jikenbo', 'Postman Pat and the Grumpy Pony', 'Shôtengai ni terebi ga kita nyo/Buchiko rankungu happyô nyu', 'Verse and Worse or Crime Without Rhyme/Truck Drivers in the Sky or Follow the Fleet', 'WPINK-TV 4');