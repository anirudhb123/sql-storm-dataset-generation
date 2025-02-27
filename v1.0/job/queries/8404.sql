
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    co.name AS company_name,
    AVG(CAST(mi.info AS numeric)) AS average_rating,
    kt.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kt ON mk.keyword_id = kt.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND c.nr_order < 3
GROUP BY 
    a.name, t.title, co.name, kt.keyword
ORDER BY 
    average_rating DESC, t.title;
