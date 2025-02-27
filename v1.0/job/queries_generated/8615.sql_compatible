
SELECT
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    p.info AS actor_info,
    STRING_AGG(DISTINCT k.keyword, ',') AS keywords,
    STRING_AGG(DISTINCT c.name, ',') AS company_names
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
WHERE 
    t.production_year > 2000
    AND p.info_type_id IN (SELECT id FROM info_type WHERE info = 'Biography')
GROUP BY 
    a.name, t.title, t.production_year, p.info
ORDER BY 
    t.production_year DESC, a.name;
