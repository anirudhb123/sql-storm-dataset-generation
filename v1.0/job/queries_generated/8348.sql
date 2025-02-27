SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.note AS role_note,
    ct.kind AS company_type,
    k.keyword AS movie_keyword,
    m.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    a.name LIKE 'A%' 
    AND t.production_year >= 2000 
    AND ct.kind ILIKE '%Production%'
ORDER BY 
    t.production_year DESC, a.name;
