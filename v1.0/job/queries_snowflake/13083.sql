SELECT 
    n.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    r.role AS role_type,
    c.note AS cast_note,
    t.production_year,
    ct.kind AS company_type,
    cn.name AS company_name,
    k.keyword AS movie_keyword
FROM 
    cast_info c
JOIN 
    aka_name n ON c.person_id = n.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
ORDER BY 
    t.production_year DESC, 
    n.name;
