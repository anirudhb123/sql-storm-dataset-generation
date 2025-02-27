SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND mi.info_type_id IN (1, 50, 92) AND mi.info = 'BUCK ROGERS BATTLES INVASION FROM FOREIGN PLANETS!...Space ships exploded by giant ray machines! Mountains crumbled by disintegrating machines!' AND t.phonetic_code IN ('E2651', 'I6512', 'K421');