SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT c.kind, ', ') AS company_types,
    STRING_AGG(DISTINCT pi.info, '; ') AS person_info
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    cast_info ci ON ci.movie_id = t.id
JOIN 
    aka_name a ON a.person_id = ci.person_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = t.id
LEFT JOIN 
    keyword k ON k.id = mk.keyword_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = t.id
LEFT JOIN 
    company_type c ON c.id = mc.company_type_id
LEFT JOIN 
    person_info pi ON pi.person_id = a.person_id
WHERE 
    t.production_year >= 2000
    AND a.name IS NOT NULL
GROUP BY 
    t.title, a.name
ORDER BY 
    movie_title, actor_name;

This query retrieves movie titles, actor names, keywords associated with the movies, types of companies involved in the films, and related personal information, all for movies produced after the year 2000. It uses various JOINs to gather more details about each movie and its associated actors, handling potential null values gracefully with LEFT JOINs and ensuring distinct values are presented through the use of `STRING_AGG` for keyword and company type aggregation.
