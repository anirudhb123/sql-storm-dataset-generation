
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    r.role AS role_type,
    c.note AS cast_note,
    STRING_AGG(DISTINCT kw.keyword, ',') AS keywords,
    STRING_AGG(DISTINCT cn.name, ',') AS company_names
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    role_type r ON c.person_role_id = r.id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = t.id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = t.id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    t.production_year >= 2000
    AND r.role IN ('Actor', 'Actress')
GROUP BY 
    a.name, t.title, t.production_year, r.role, c.note
ORDER BY 
    t.production_year DESC, a.name;
