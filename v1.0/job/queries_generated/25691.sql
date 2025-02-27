SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.gender AS person_gender,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword SEPARATOR ', ') AS keywords,
    GROUP_CONCAT(DISTINCT c.kind ORDER BY c.kind SEPARATOR ', ') AS company_types
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    name p ON a.person_id = p.imdb_id
WHERE 
    t.production_year >= 2000
    AND a.name IS NOT NULL
GROUP BY 
    a.id, t.id, p.gender
ORDER BY 
    t.production_year DESC, a.name ASC;
