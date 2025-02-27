
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    c.kind AS cast_type,
    cp.name AS company_name,
    p.info AS actor_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cp ON mc.company_id = cp.id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    t.production_year >= 2000
    AND a.name IS NOT NULL
    AND cp.country_code = 'USA'
GROUP BY 
    a.name, t.title, t.production_year, c.kind, cp.name, p.info
ORDER BY 
    t.production_year DESC, a.name;
