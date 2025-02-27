SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS role_kind,
    m.production_year,
    COUNT(DISTINCT m.id) AS total_movies,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    aka_title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND co.country_code = 'USA'
GROUP BY 
    t.title, a.name, c.kind, m.production_year
ORDER BY 
    total_movies DESC, m.production_year DESC
LIMIT 100;
