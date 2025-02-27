SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    r.role AS role,
    c.note AS cast_note,
    m.name AS company_name,
    kt.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name m ON mc.company_id = m.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kt ON mk.keyword_id = kt.id
ORDER BY 
    t.production_year DESC, a.name;
