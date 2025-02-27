SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    c.kind AS company_type,
    g.kind AS genre,
    k.keyword AS movie_keyword,
    p.info AS person_info,
    m.info AS movie_info
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    kind_type g ON t.kind_id = g.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info p ON ak.person_id = p.person_id
JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND c.kind ILIKE '%Studios%'
    AND k.keyword IS NOT NULL
ORDER BY 
    t.production_year DESC, 
    ak.name;
