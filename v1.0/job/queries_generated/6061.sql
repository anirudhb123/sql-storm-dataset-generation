SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    p.name AS person_name,
    r.role AS role_name,
    c.kind AS company_type,
    m.production_year AS release_year,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword SEPARATOR ', ') AS keywords
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    person_info pi ON ak.person_id = pi.person_id
WHERE 
    t.production_year > 2000
    AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Birth Date')
    AND c.country_code = 'USA'
GROUP BY 
    ak.name, t.title, p.name, r.role, c.kind, m.production_year
ORDER BY 
    release_year DESC, movie_title ASC;
