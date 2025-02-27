SELECT 
    t.title,
    a.name AS actor_name,
    p.info AS person_info,
    k.keyword AS movie_keyword,
    c.name AS company_name,
    m.info AS movie_info
FROM 
    title t
JOIN 
    aka_title a ON t.id = a.movie_id
JOIN 
    cast_info ci ON a.id = ci.movie_id
JOIN 
    aka_name an ON ci.person_id = an.person_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    movie_info m ON t.id = m.movie_id
LEFT JOIN 
    person_info p ON an.person_id = p.person_id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.title, a.name;
