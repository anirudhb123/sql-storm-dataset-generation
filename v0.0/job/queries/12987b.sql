SELECT min(mi.info) AS movie_budget, min(mi_idx.info) AS movie_votes, min(t.title) AS movie_title
FROM cast_info AS ci, info_type AS it1, info_type AS it2, movie_info AS mi, movie_info_idx AS mi_idx, name AS n, title AS t
WHERE t.id = mi.movie_id AND t.id = mi_idx.movie_id AND t.id = ci.movie_id AND ci.movie_id = mi.movie_id AND ci.movie_id = mi_idx.movie_id AND mi.movie_id = mi_idx.movie_id AND n.id = ci.person_id AND it1.id = mi.info_type_id AND it2.id = mi_idx.info_type_id
AND ci.person_id IN (2545687, 3141582, 3491000, 3599625, 415120, 458138, 556163) AND n.surname_pcode > 'M453';