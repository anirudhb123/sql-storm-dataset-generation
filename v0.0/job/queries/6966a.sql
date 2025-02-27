SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND mi.info > 'Gleiberman, Owen. "All That Glitters.". In: "Entertainment Weekly" (USA), Iss. 458, 13 November 1998, Pg. 52, (MG)' AND t.md5sum LIKE '%ba8%' AND t.season_nr IN (102, 11, 15, 1990, 23, 43, 91) AND t.episode_of_id IS NOT NULL;