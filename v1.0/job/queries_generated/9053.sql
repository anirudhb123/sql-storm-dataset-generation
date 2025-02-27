SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.first_name || ' ' || p.last_name AS actor_name,
    c.kind AS role_type,
    m.info AS movie_info,
    k.keyword AS movie_keyword,
    COALESCE(mn.name, 'Unknown') AS company_name
FROM 
    aka_name a 
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type c ON ci.role_id = c.id
LEFT JOIN 
    movie_info m ON t.id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name mn ON mc.company_id = mn.id
JOIN 
    name p ON ci.person_id = p.imdb_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, a.name;
