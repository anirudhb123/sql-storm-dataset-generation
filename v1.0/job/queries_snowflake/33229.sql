
WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        c.person_id,
        a.name,
        1 AS level
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        c.movie_id = (SELECT id FROM aka_title WHERE title ILIKE '%The Matrix%' LIMIT 1)
    
    UNION ALL

    SELECT 
        c.person_id,
        a.name,
        ah.level + 1
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        ActorHierarchy ah ON ah.person_id = c.movie_id
)

SELECT 
    a.name AS ActorName,
    t.title AS MovieTitle,
    t.production_year AS Year,
    COUNT(DISTINCT c.id) AS CastCount,
    LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS Keywords,
    SUM(CASE WHEN p.info_type_id = (SELECT id FROM info_type WHERE info = 'salary') THEN CAST(p.info AS numeric) ELSE 0 END) AS TotalSalary,
    AVG(CASE WHEN p.info_type_id = (SELECT id FROM info_type WHERE info = 'age') THEN CAST(p.info AS numeric) END) AS AvgAge,
    MAX(t.production_year) OVER () AS LatestProductionYear
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    t.production_year >= 2000
GROUP BY 
    a.name, t.title, t.production_year
ORDER BY 
    TotalSalary DESC NULLS LAST,
    AvgAge DESC;
