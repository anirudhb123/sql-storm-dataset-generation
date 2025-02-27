SELECT 
    t.title AS movie_title, 
    a.name AS actor_name, 
    r.role AS actor_role, 
    c.note AS cast_note, 
    co.name AS company_name, 
    ct.kind AS company_type, 
    t.production_year, 
    k.keyword AS movie_keyword
FROM 
    title t
JOIN 
    cast_info c ON t.id = c.movie_id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year >= 2000 
    AND a.name ILIKE '%Smith%' 
    AND co.country_code = 'USA'
ORDER BY 
    t.production_year DESC, 
    a.name, 
    t.title;
