SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS role_order,
    c.note AS role_note,
    m.info AS movie_info,
    k.keyword AS movie_keyword,
    co.name AS company_name,
    ct.kind AS company_type
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    t.production_year > 2000
    AND c.role_id IN (SELECT id FROM role_type WHERE role LIKE '%lead%')
ORDER BY 
    a.name, t.production_year DESC;
