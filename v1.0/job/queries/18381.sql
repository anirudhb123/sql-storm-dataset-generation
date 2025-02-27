SELECT p.name AS person_name, m.title AS movie_title, c.nr_order AS cast_order
FROM cast_info c
JOIN aka_name p ON c.person_id = p.person_id
JOIN aka_title m ON c.movie_id = m.movie_id
WHERE m.production_year = 2020
ORDER BY c.nr_order;
