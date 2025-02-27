
SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    AVG(CASE 
        WHEN ci.note IS NOT NULL THEN 1 
        ELSE 0 
    END) AS has_note,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    COUNT(DISTINCT p.id) AS people_info
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    t.production_year BETWEEN 2000 AND 2020 
    AND at.kind_id = (SELECT id FROM kind_type WHERE kind = 'feature')
GROUP BY 
    t.title, a.name
ORDER BY 
    movie_title, actor_name;
