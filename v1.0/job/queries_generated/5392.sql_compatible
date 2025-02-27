
SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    t.production_year, 
    co.name AS company_name, 
    rt.role AS role_name, 
    COUNT(DISTINCT k.keyword) AS keyword_count 
FROM 
    cast_info ci 
JOIN 
    aka_name a ON ci.person_id = a.person_id 
JOIN 
    aka_title t ON ci.movie_id = t.movie_id 
JOIN 
    movie_companies mc ON mc.movie_id = t.id 
JOIN 
    company_name co ON mc.company_id = co.id 
JOIN 
    movie_keyword mk ON mk.movie_id = t.id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
JOIN 
    role_type rt ON ci.role_id = rt.id 
WHERE 
    t.production_year >= 2000 
    AND rt.role IN ('Actor', 'Actress') 
GROUP BY 
    a.name, t.title, t.production_year, co.name, rt.role 
ORDER BY 
    keyword_count DESC, t.production_year DESC 
LIMIT 10;
