
SELECT 
    an.name AS actor_name,
    m.title AS movie_title,
    c.kind AS cast_type,
    ci.note AS cast_note,
    m.production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    aka_name an
JOIN 
    cast_info ci ON an.person_id = ci.person_id
JOIN 
    title m ON ci.movie_id = m.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    movie_keyword mk ON m.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    m.production_year >= 2000
    AND c.kind IN ('actor', 'actress')
GROUP BY 
    an.name, m.title, c.kind, ci.note, m.production_year
ORDER BY 
    m.production_year DESC, actor_name ASC;
