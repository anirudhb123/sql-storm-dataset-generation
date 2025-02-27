
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    p.info AS actor_bio,
    STRING_AGG(DISTINCT k.keyword, ', ' ORDER BY k.keyword) AS keywords,
    STRING_AGG(DISTINCT c.name, ', ' ORDER BY c.name) AS companies
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
WHERE 
    a.name IS NOT NULL
    AND t.production_year >= 2000
    AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
GROUP BY 
    a.name, t.title, t.production_year, p.info
ORDER BY 
    t.production_year DESC, a.name;
