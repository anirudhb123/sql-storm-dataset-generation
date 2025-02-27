SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    t.production_year, 
    c.nr_order AS cast_order, 
    ARRAY_AGG(DISTINCT k.keyword) AS keywords, 
    COALESCE(cct.kind, 'N/A') AS cast_type 
FROM 
    aka_name a 
JOIN 
    cast_info c ON a.person_id = c.person_id 
JOIN 
    title t ON c.movie_id = t.id 
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id 
LEFT JOIN 
    comp_cast_type cct ON c.person_role_id = cct.id 
WHERE 
    t.production_year >= 2000 
GROUP BY 
    a.name, t.title, t.production_year, c.nr_order, cct.kind 
ORDER BY 
    t.production_year DESC, a.name;
