SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND mk.id IN (1058185, 2372308, 2704253, 2876240, 3555330, 3985193, 4460224, 638869, 771607) AND t.kind_id IN (1, 3, 7) AND k.keyword > 'assault-rifle';