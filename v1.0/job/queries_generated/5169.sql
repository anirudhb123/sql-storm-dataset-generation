SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    y.production_year,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    GROUP_CONCAT(DISTINCT c.kind) AS company_types
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
    movie_info mi ON t.id = mi.movie_id
WHERE 
    a.name LIKE '%Smith%'
    AND t.production_year >= 2000
    AND mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%award%')
GROUP BY 
    a.name, t.title, y.production_year
ORDER BY 
    y.production_year DESC;
