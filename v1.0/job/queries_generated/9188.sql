SELECT 
    at.title AS movie_title,
    ak.name AS actor_name,
    ct.kind AS character_role,
    c.company_name,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    MAX(mi.info) AS additional_info
FROM 
    aka_title at
JOIN 
    cast_info ci ON at.id = ci.movie_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    role_type ct ON ci.role_id = ct.id
JOIN 
    movie_companies mc ON at.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON at.id = mi.movie_id
WHERE 
    at.production_year >= 2000
    AND ak.name IS NOT NULL
    AND c.country_code = 'USA'
GROUP BY 
    at.title, ak.name, ct.kind, c.company_name
ORDER BY 
    at.production_year DESC, ak.name;
