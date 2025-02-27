
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    ct.kind AS company_type,
    COUNT(mi.info) AS info_count,
    STRING_AGG(DISTINCT kw.keyword, ',') AS keywords,
    COUNT(DISTINCT c.person_id) AS co_actors_count
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    t.production_year >= 2000 
    AND ct.kind IS NOT NULL
GROUP BY 
    a.name, t.title, ct.kind
ORDER BY 
    info_count DESC, a.name ASC;
