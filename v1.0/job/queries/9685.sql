SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    c.kind AS company_kind,
    COUNT(DISTINCT m.company_id) AS company_count
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies m ON t.id = m.movie_id
JOIN 
    company_type c ON m.company_type_id = c.id
WHERE 
    a.name IS NOT NULL
    AND t.production_year >= 2000
    AND t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'feature')
GROUP BY 
    a.name, t.title, t.production_year, c.kind
ORDER BY 
    t.production_year DESC, actor_name;
