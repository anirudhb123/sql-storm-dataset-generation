
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    c.kind AS cast_type,
    ci.note AS cast_note
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    comp_cast_type c ON ci.role_id = c.id
WHERE 
    t.production_year >= 2000 AND 
    a.name IS NOT NULL
GROUP BY 
    a.name, t.title, t.production_year, c.kind, ci.note
ORDER BY 
    t.production_year DESC, 
    actor_name ASC;
