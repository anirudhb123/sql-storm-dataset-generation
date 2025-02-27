SELECT a.name AS actor_name, m.title AS movie_title, y.production_year
FROM aka_name a
JOIN cast_info c ON a.person_id = c.person_id
JOIN aka_title m ON c.movie_id = m.id
JOIN title y ON m.movie_id = y.id
WHERE y.production_year >= 2000
ORDER BY y.production_year DESC;
