SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    GROUP_CONCAT(DISTINCT c.kind ORDER BY c.kind SEPARATOR ', ') AS company_types,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword SEPARATOR ', ') AS keywords,
    MAX(t.production_year) AS latest_production_year,
    COUNT(DISTINCT p.id) AS total_persons
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
    person_info p ON a.person_id = p.person_id
WHERE 
    t.production_year >= 2000 
    AND c.kind IN ('Distributor', 'Producer')
    AND k.keyword LIKE '%action%'
GROUP BY 
    a.name, t.title
ORDER BY 
    latest_production_year DESC, total_persons DESC
LIMIT 100;
