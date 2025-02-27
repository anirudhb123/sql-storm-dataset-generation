WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        c.person_id,
        c.movie_id,
        1 AS depth
    FROM 
        cast_info c
    WHERE 
        c.role_id IS NOT NULL

    UNION ALL

    SELECT 
        c.person_id,
        c.movie_id,
        h.depth + 1
    FROM 
        cast_info c
    JOIN 
        ActorHierarchy h ON c.movie_id = h.movie_id
    WHERE 
        c.role_id IS NOT NULL AND c.person_id != h.person_id
)

SELECT 
    t.title AS Movie_Title,
    COALESCE(a.name, 'Unknown Actor') AS Actor_Name,
    COUNT(DISTINCT c.id) AS Total_Cast_Count,
    AVG(h.depth) AS Average_Depth,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS Keywords,
    r.role AS Role,
    COUNT(DISTINCT mc.company_id) AS Production_Companies,
    SUM(CASE WHEN pi.info IS NOT NULL THEN 1 ELSE 0 END) AS Person_Info_Count
FROM 
    title t
LEFT JOIN 
    aka_title at ON t.id = at.movie_id
LEFT JOIN 
    cast_info c ON t.id = c.movie_id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN 
    role_type r ON c.role_id = r.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
LEFT JOIN 
    ActorHierarchy h ON c.movie_id = h.movie_id
WHERE 
    t.production_year >= 2000
GROUP BY 
    t.title, Actor_Name, r.role
ORDER BY 
    Movie_Title, Total_Cast_Count DESC;
