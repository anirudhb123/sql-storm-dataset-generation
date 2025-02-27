
SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    t.production_year, 
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords, 
    c.kind AS cast_type, 
    cn.name AS company_name
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    t.production_year > 2000
    AND c.kind IN ('Actor', 'Producer')
GROUP BY 
    a.name, t.title, t.production_year, c.kind, cn.name
ORDER BY 
    t.production_year DESC, a.name;
