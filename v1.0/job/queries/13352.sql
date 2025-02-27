SELECT 
    n.name AS actor_name,
    t.title AS movie_title,
    c.note AS role_note,
    t.production_year,
    com.name AS company_name,
    k.keyword AS movie_keyword
FROM 
    cast_info c
JOIN 
    aka_name n ON c.person_id = n.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name com ON mc.company_id = com.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, 
    n.name;
