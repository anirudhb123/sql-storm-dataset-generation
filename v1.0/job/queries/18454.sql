SELECT a.title, p.name, c.nr_order
FROM title a
JOIN complete_cast b ON a.id = b.movie_id
JOIN cast_info c ON b.subject_id = c.person_id
JOIN aka_name p ON c.person_id = p.person_id
WHERE a.production_year = 2020
ORDER BY a.title, c.nr_order;
