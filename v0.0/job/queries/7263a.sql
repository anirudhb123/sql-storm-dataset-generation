SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.title IN ('A Trick of the Sun', 'Better Than Therapy', 'Liberace: Behind the Music', 'MILF Affairs: Abigail Toyne', 'One Tree Hill: Always & Forever', 'Sperling & Brooke') AND mi.info < 'Has been accepted to 12 Film Festivals worldwide and won the Platinum Award at the Houston Film Festival' AND k.phonetic_code < 'R5126';