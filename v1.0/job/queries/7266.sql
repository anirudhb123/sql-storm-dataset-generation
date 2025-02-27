
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    p.info AS actor_info,
    c.kind AS cast_type,
    STRING_AGG(k.keyword, ', ') AS keywords,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    COUNT(DISTINCT ml.linked_movie_id) AS linked_movies
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    movie_link ml ON t.id = ml.movie_id
WHERE 
    p.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
    AND t.production_year BETWEEN 2000 AND 2020
GROUP BY 
    a.name, t.title, p.info, c.kind
ORDER BY 
    actor_name, movie_title;
