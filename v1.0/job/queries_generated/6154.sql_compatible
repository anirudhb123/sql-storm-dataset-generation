
SELECT 
    an.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    t.production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    aka_name an
JOIN 
    cast_info ci ON an.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    t.production_year >= 2000 AND 
    cn.country_code = 'USA'
GROUP BY 
    an.name, t.title, c.kind, t.production_year
ORDER BY 
    t.production_year DESC, an.name;
