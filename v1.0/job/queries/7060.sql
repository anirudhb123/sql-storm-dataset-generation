SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    k.keyword AS movie_keyword,
    pi.info AS person_info,
    CASE 
        WHEN c1.role IS NOT NULL THEN c1.role 
        ELSE 'Unknown Role' 
    END AS role_description
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info pi ON a.person_id = pi.person_id
JOIN 
    role_type c1 ON ci.role_id = c1.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
  AND 
    a.name IS NOT NULL
  AND 
    pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
