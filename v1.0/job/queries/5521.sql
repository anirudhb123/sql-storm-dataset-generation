SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    p.info AS actor_bio,
    c.name AS company_name,
    ct.kind AS company_type,
    STRING_AGG(k.keyword, ', ') AS keywords
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    a.name IS NOT NULL
    AND t.production_year BETWEEN 2000 AND 2023
    AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
GROUP BY 
    a.name, t.title, t.production_year, p.info, c.name, ct.kind
ORDER BY 
    t.production_year DESC, a.name;
