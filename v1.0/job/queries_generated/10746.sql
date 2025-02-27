SELECT 
    t.title, 
    a.name AS actor_name, 
    c.kind AS company_type, 
    k.keyword AS movie_keyword,
    m.production_year
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    cast_info ci ON ci.movie_id = at.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON mk.movie_id = t.id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON mi.movie_id = t.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.title;
