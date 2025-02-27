SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    CASE 
        WHEN mi.info IS NOT NULL THEN mi.info
        ELSE 'No info' 
    END AS movie_info,
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    a.name LIKE '%Smith%'
    AND t.production_year > 2000
    AND ct.kind IN ('Production', 'Distribution')
ORDER BY 
    t.production_year DESC, a.name ASC;
