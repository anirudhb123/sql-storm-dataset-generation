SELECT 
    t.title, 
    a.name AS actor_name, 
    k.keyword 
FROM 
    aka_name a 
JOIN 
    cast_info ci ON a.person_id = ci.person_id 
JOIN 
    title t ON ci.movie_id = t.id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
WHERE 
    t.production_year > 2000 
ORDER BY 
    t.production_year DESC;
