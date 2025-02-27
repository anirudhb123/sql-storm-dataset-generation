SELECT 
    ak.name AS aka_name, 
    t.title AS movie_title, 
    c.nr_order AS actor_order, 
    p.info AS person_info, 
    co.name AS company_name, 
    ki.keyword AS movie_keyword, 
    COUNT(DISTINCT ml.linked_movie_id) AS total_linked_movies 
FROM 
    aka_name ak 
JOIN 
    cast_info c ON ak.person_id = c.person_id 
JOIN 
    title t ON c.movie_id = t.id 
JOIN 
    person_info p ON ak.person_id = p.person_id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name co ON mc.company_id = co.id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword ki ON mk.keyword_id = ki.id 
LEFT JOIN 
    movie_link ml ON t.id = ml.movie_id 
WHERE 
    t.production_year > 2000 
    AND p.info_type_id IN (SELECT id FROM info_type WHERE info = 'Biography') 
GROUP BY 
    ak.name, t.title, c.nr_order, p.info, co.name, ki.keyword 
ORDER BY 
    total_linked_movies DESC, t.title ASC 
LIMIT 10;
